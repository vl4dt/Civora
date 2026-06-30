defmodule Civora.Evidence do
  @moduledoc """
  Metadata and storage workflow for project evidence attachments.
  """

  import Ecto.Query, warn: false

  alias Civora.Accounts.{Scope, User}
  alias Civora.Audit
  alias Civora.Budget.WorkItem
  alias Civora.Evidence.EvidenceAttachment
  alias Civora.Execution.ExecutedProgressEntry
  alias Civora.Projects
  alias Civora.Projects.Project
  alias Civora.Quality.{NonConformity, QualityControl}
  alias Civora.Repo
  alias Civora.Storage

  @parent_fields [:executed_progress_entry_id, :quality_control_id, :non_conformity_id]

  def change_evidence_attachment(%EvidenceAttachment{} = attachment, attrs \\ %{}) do
    EvidenceAttachment.changeset(attachment, attrs)
  end

  def list_work_item_attachments(
        %Scope{} = scope,
        %Project{} = project,
        %WorkItem{} = work_item
      ) do
    with true <- Projects.authorized?(scope, project, :view),
         %WorkItem{} <- work_item_for_project(project, work_item.id) do
      attachments =
        from(a in EvidenceAttachment,
          where: a.project_id == ^project.id and a.work_item_id == ^work_item.id,
          join: uploaded_by in assoc(a, :uploaded_by),
          left_join: invalidated_by in assoc(a, :invalidated_by),
          preload: [uploaded_by: uploaded_by, invalidated_by: invalidated_by],
          order_by: [desc: a.inserted_at, desc: a.id]
        )
        |> Repo.all()

      {:ok, attachments}
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
    end
  end

  def create_attachment(
        %Scope{user: %User{} = actor} = scope,
        %Project{} = project,
        %WorkItem{} = work_item,
        attrs
      ) do
    with true <- Projects.authorized?(scope, project, :manage_quality),
         %WorkItem{} = stored_work_item <- work_item_for_project(project, work_item.id),
         {:ok, parent_attrs} <- parent_attrs(project, stored_work_item, attrs),
         {:ok, file_attrs} <- file_attrs(attrs),
         object_key <- object_key(project, stored_work_item, parent_attrs, file_attrs),
         :ok <-
           Storage.put_object(object_key, file_attrs.body, content_type: file_attrs.content_type) do
      attrs =
        attrs
        |> Map.drop(["body", :body])
        |> put_attrs(parent_attrs)
        |> put_attr(:project_id, project.id)
        |> put_attr(:work_item_id, stored_work_item.id)
        |> put_attr(:uploaded_by_id, actor.id)
        |> put_attr(:object_key, object_key)
        |> put_attr(:original_filename, file_attrs.original_filename)
        |> put_attr(:content_type, file_attrs.content_type)
        |> put_attr(:byte_size, file_attrs.byte_size)

      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :attachment,
        EvidenceAttachment.changeset(%EvidenceAttachment{}, attrs)
      )
      |> Ecto.Multi.insert(:audit_event, fn %{attachment: attachment} ->
        Audit.event_changeset(actor, project, %{
          action: :evidence_uploaded,
          entity_type: "evidence_attachment",
          entity_id: attachment.id,
          new_state: attachment_state(attachment)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{attachment: attachment}} -> {:ok, Repo.preload(attachment, :uploaded_by)}
        {:error, :attachment, changeset, _changes} -> {:error, changeset}
        {:error, _operation, reason, _changes} -> {:error, reason}
      end
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def invalidate_attachment(
        %Scope{user: %User{} = actor} = scope,
        %Project{} = project,
        %EvidenceAttachment{} = attachment,
        attrs
      ) do
    with true <- Projects.authorized?(scope, project, :manage_quality),
         %EvidenceAttachment{} = stored_attachment <-
           attachment_for_project(project, attachment.id),
         :ok <- ensure_valid(stored_attachment) do
      previous_state = attachment_state(stored_attachment)

      invalidation_attrs =
        attrs
        |> put_attr(:invalidated_by_id, actor.id)
        |> put_attr(:invalidated_at, DateTime.utc_now() |> DateTime.truncate(:second))

      Ecto.Multi.new()
      |> Ecto.Multi.update(
        :attachment,
        EvidenceAttachment.invalidate_changeset(stored_attachment, invalidation_attrs)
      )
      |> Ecto.Multi.insert(:audit_event, fn %{attachment: invalidated_attachment} ->
        Audit.event_changeset(actor, project, %{
          action: :evidence_invalidated,
          entity_type: "evidence_attachment",
          entity_id: invalidated_attachment.id,
          reason: invalidated_attachment.invalidation_reason,
          previous_state: previous_state,
          new_state: attachment_state(invalidated_attachment)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{attachment: attachment}} ->
          {:ok, Repo.preload(attachment, [:uploaded_by, :invalidated_by])}

        {:error, :attachment, changeset, _changes} ->
          {:error, changeset}

        {:error, _operation, reason, _changes} ->
          {:error, reason}
      end
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp file_attrs(attrs) do
    body = Map.get(attrs, "body") || Map.get(attrs, :body)
    original_filename = Map.get(attrs, "original_filename") || Map.get(attrs, :original_filename)
    content_type = Map.get(attrs, "content_type") || Map.get(attrs, :content_type)
    byte_size = Map.get(attrs, "byte_size") || Map.get(attrs, :byte_size)

    cond do
      not is_binary(body) or byte_size(body) == 0 ->
        {:error, :empty_file}

      blank?(original_filename) ->
        {:error, :missing_filename}

      blank?(content_type) ->
        {:error, :missing_content_type}

      true ->
        {:ok,
         %{
           body: body,
           original_filename: Path.basename(original_filename),
           content_type: content_type,
           byte_size: byte_size || byte_size(body)
         }}
    end
  end

  defp parent_attrs(project, work_item, attrs) do
    parent_values =
      Map.new(@parent_fields, fn field ->
        value = Map.get(attrs, to_string(field)) || Map.get(attrs, field)
        {field, blank_to_nil(value)}
      end)

    case Enum.reject(parent_values, fn {_field, value} -> is_nil(value) end) do
      [{:executed_progress_entry_id, id}] ->
        case Repo.get_by(ExecutedProgressEntry,
               id: id,
               project_id: project.id,
               work_item_id: work_item.id
             ) do
          %ExecutedProgressEntry{} = entry ->
            {:ok, %{executed_progress_entry_id: entry.id}}

          nil ->
            {:error, :not_found}
        end

      [{:quality_control_id, id}] ->
        case Repo.get_by(QualityControl,
               id: id,
               project_id: project.id,
               work_item_id: work_item.id
             ) do
          %QualityControl{} = control -> {:ok, %{quality_control_id: control.id}}
          nil -> {:error, :not_found}
        end

      [{:non_conformity_id, id}] ->
        case Repo.get_by(NonConformity,
               id: id,
               project_id: project.id,
               work_item_id: work_item.id
             ) do
          %NonConformity{} = non_conformity -> {:ok, %{non_conformity_id: non_conformity.id}}
          nil -> {:error, :not_found}
        end

      [] ->
        {:error, :missing_parent}

      _many ->
        {:error, :multiple_parents}
    end
  end

  defp object_key(project, work_item, parent_attrs, file_attrs) do
    {parent_type, parent_id} =
      cond do
        parent_attrs[:executed_progress_entry_id] ->
          {"executed-progress", parent_attrs[:executed_progress_entry_id]}

        parent_attrs[:quality_control_id] ->
          {"quality-controls", parent_attrs[:quality_control_id]}

        parent_attrs[:non_conformity_id] ->
          {"non-conformities", parent_attrs[:non_conformity_id]}
      end

    extension = Path.extname(file_attrs.original_filename)
    unique = System.unique_integer([:positive])

    "evidence/projects/#{project.id}/work-items/#{work_item.id}/#{parent_type}/#{parent_id}/#{unique}#{extension}"
  end

  defp work_item_for_project(%Project{id: project_id}, work_item_id) do
    Repo.get_by(WorkItem, id: work_item_id, project_id: project_id)
  end

  defp attachment_for_project(%Project{id: project_id}, attachment_id) do
    Repo.get_by(EvidenceAttachment, id: attachment_id, project_id: project_id)
  end

  defp ensure_valid(%EvidenceAttachment{status: :valid}), do: :ok
  defp ensure_valid(%EvidenceAttachment{status: :invalidated}), do: {:error, :already_invalidated}

  defp put_attrs(attrs, values) do
    Enum.reduce(values, attrs, fn {key, value}, acc -> put_attr(acc, key, value) end)
  end

  defp put_attr(attrs, key, value) do
    if Enum.any?(Map.keys(attrs), &is_binary/1),
      do: Map.put(attrs, to_string(key), value),
      else: Map.put(attrs, key, value)
  end

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value

  defp blank?(value), do: value in [nil, ""]

  defp attachment_state(attachment) do
    %{
      "work_item_id" => attachment.work_item_id,
      "executed_progress_entry_id" => attachment.executed_progress_entry_id,
      "quality_control_id" => attachment.quality_control_id,
      "non_conformity_id" => attachment.non_conformity_id,
      "object_key" => attachment.object_key,
      "original_filename" => attachment.original_filename,
      "content_type" => attachment.content_type,
      "byte_size" => attachment.byte_size,
      "status" => to_string(attachment.status),
      "uploaded_by_id" => attachment.uploaded_by_id,
      "invalidated_by_id" => attachment.invalidated_by_id,
      "invalidated_at" => datetime_to_string(attachment.invalidated_at),
      "invalidation_reason" => attachment.invalidation_reason
    }
  end

  defp datetime_to_string(nil), do: nil
  defp datetime_to_string(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
end
