defmodule Civora.Quality do
  @moduledoc """
  Project quality acceptance and rejection controls.
  """

  import Ecto.Query, warn: false

  alias Civora.Accounts.{Scope, User}
  alias Civora.Audit
  alias Civora.Budget.WorkItem
  alias Civora.Execution.ExecutedProgressEntry
  alias Civora.Projects
  alias Civora.Projects.Project
  alias Civora.Quality.{NonConformity, QualityControl}
  alias Civora.Repo

  def change_quality_control(%QualityControl{} = control, attrs \\ %{}) do
    QualityControl.changeset(control, attrs)
  end

  def change_non_conformity(%NonConformity{} = non_conformity, attrs \\ %{}) do
    NonConformity.changeset(non_conformity, attrs)
  end

  def list_work_item_quality_controls(
        %Scope{} = scope,
        %Project{} = project,
        %WorkItem{} = work_item
      ) do
    with true <- Projects.authorized?(scope, project, :view),
         %WorkItem{} <- work_item_for_project(project, work_item.id) do
      controls =
        from(c in QualityControl,
          where: c.project_id == ^project.id and c.work_item_id == ^work_item.id,
          join: e in assoc(c, :executed_progress_entry),
          preload: [executed_progress_entry: e],
          order_by: [desc: c.inserted_at, desc: c.id]
        )
        |> Repo.all()

      {:ok, controls}
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
    end
  end

  def list_work_item_non_conformities(
        %Scope{} = scope,
        %Project{} = project,
        %WorkItem{} = work_item
      ) do
    with true <- Projects.authorized?(scope, project, :view),
         %WorkItem{} <- work_item_for_project(project, work_item.id) do
      non_conformities =
        from(n in NonConformity,
          where: n.project_id == ^project.id and n.work_item_id == ^work_item.id,
          left_join: c in assoc(n, :quality_control),
          left_join: e in assoc(n, :executed_progress_entry),
          preload: [quality_control: c, executed_progress_entry: e],
          order_by: [asc: n.status, desc: n.inserted_at, desc: n.id]
        )
        |> Repo.all()

      {:ok, non_conformities}
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
    end
  end

  def get_work_item_payable_progress(
        %Scope{} = scope,
        %Project{} = project,
        %WorkItem{} = work_item
      ) do
    with {:ok, summaries} <- list_work_items_payable_progress(scope, project, [work_item]) do
      {:ok, Map.fetch!(summaries, work_item.id)}
    end
  end

  def list_work_items_payable_progress(%Scope{} = scope, %Project{} = project, work_items)
      when is_list(work_items) do
    work_item_ids = Enum.map(work_items, & &1.id)

    with true <- Projects.authorized?(scope, project, :view),
         :ok <- work_items_belong_to_project(project, work_item_ids) do
      executed_by_work_item =
        from(e in ExecutedProgressEntry,
          where: e.project_id == ^project.id and e.work_item_id in ^work_item_ids,
          group_by: e.work_item_id,
          select: {e.work_item_id, sum(e.quantity)}
        )
        |> Repo.all()
        |> Map.new()

      quality_by_work_item =
        from(c in QualityControl,
          where: c.project_id == ^project.id and c.work_item_id in ^work_item_ids,
          group_by: c.work_item_id,
          select: {c.work_item_id, sum(c.accepted_quantity), sum(c.rejected_quantity)}
        )
        |> Repo.all()
        |> Map.new(fn {work_item_id, accepted_quantity, rejected_quantity} ->
          {work_item_id,
           %{
             accepted_quantity: accepted_quantity || zero(),
             rejected_quantity: rejected_quantity || zero()
           }}
        end)

      open_non_conformities_by_work_item =
        from(n in NonConformity,
          where:
            n.project_id == ^project.id and n.work_item_id in ^work_item_ids and
              n.status == :open,
          group_by: n.work_item_id,
          select: {n.work_item_id, sum(n.affected_quantity)}
        )
        |> Repo.all()
        |> Map.new()

      summaries =
        Map.new(work_items, fn work_item ->
          quality =
            Map.get(quality_by_work_item, work_item.id, %{
              accepted_quantity: zero(),
              rejected_quantity: zero()
            })

          summary = %{
            work_item_id: work_item.id,
            executed_quantity: Map.get(executed_by_work_item, work_item.id, zero()),
            payable_quantity: quality.accepted_quantity,
            accepted_quantity: quality.accepted_quantity,
            rejected_quantity: quality.rejected_quantity,
            open_non_conformity_quantity:
              Map.get(open_non_conformities_by_work_item, work_item.id, zero())
          }

          {work_item.id, summary}
        end)

      {:ok, summaries}
    else
      false -> {:error, :unauthorized}
      {:error, reason} -> {:error, reason}
    end
  end

  def create_quality_control(
        %Scope{user: %User{} = actor} = scope,
        %Project{} = project,
        %ExecutedProgressEntry{} = entry,
        attrs
      ) do
    with true <- Projects.authorized?(scope, project, :manage_quality),
         %ExecutedProgressEntry{} = stored_entry <-
           executed_progress_for_project(project, entry.id),
         {:ok, control_attrs} <- control_attrs(stored_entry, attrs) do
      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :quality_control,
        QualityControl.changeset(%QualityControl{}, control_attrs)
      )
      |> Ecto.Multi.update(:executed_progress, fn %{quality_control: control} ->
        ExecutedProgressEntry.payable_changeset(
          stored_entry,
          Decimal.gt?(control.accepted_quantity, 0)
        )
      end)
      |> Ecto.Multi.insert(:audit_event, fn %{quality_control: control} ->
        Audit.event_changeset(actor, project, %{
          action: audit_action(control),
          entity_type: "quality_control",
          entity_id: control.id,
          reason: control.rejection_reason,
          new_state: quality_control_state(control)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{quality_control: control}} -> {:ok, control}
        {:error, :quality_control, changeset, _changes} -> {:error, changeset}
        {:error, _operation, reason, _changes} -> {:error, reason}
      end
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def create_non_conformity(
        %Scope{user: %User{} = actor} = scope,
        %Project{} = project,
        %WorkItem{} = work_item,
        attrs
      ) do
    with true <- Projects.authorized?(scope, project, :manage_quality),
         %WorkItem{} = stored_work_item <- work_item_for_project(project, work_item.id),
         {:ok, non_conformity_attrs} <- non_conformity_attrs(project, stored_work_item, attrs) do
      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :non_conformity,
        NonConformity.changeset(%NonConformity{}, non_conformity_attrs)
      )
      |> Ecto.Multi.insert(:audit_event, fn %{non_conformity: non_conformity} ->
        Audit.event_changeset(actor, project, %{
          action: :non_conformity_created,
          entity_type: "non_conformity",
          entity_id: non_conformity.id,
          reason: non_conformity.defect,
          new_state: non_conformity_state(non_conformity)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{non_conformity: non_conformity}} -> {:ok, non_conformity}
        {:error, :non_conformity, changeset, _changes} -> {:error, changeset}
        {:error, _operation, reason, _changes} -> {:error, reason}
      end
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def close_non_conformity(
        %Scope{user: %User{} = actor} = scope,
        %Project{} = project,
        %NonConformity{} = non_conformity,
        attrs
      ) do
    with true <- Projects.authorized?(scope, project, :manage_quality),
         %NonConformity{} = stored_non_conformity <-
           non_conformity_for_project(project, non_conformity.id),
         :ok <- ensure_open(stored_non_conformity) do
      previous_state = non_conformity_state(stored_non_conformity)

      Ecto.Multi.new()
      |> Ecto.Multi.update(
        :non_conformity,
        NonConformity.close_changeset(
          stored_non_conformity,
          put_closed_at(attrs, DateTime.utc_now() |> DateTime.truncate(:second))
        )
      )
      |> Ecto.Multi.insert(:audit_event, fn %{non_conformity: closed_non_conformity} ->
        Audit.event_changeset(actor, project, %{
          action: :non_conformity_closed,
          entity_type: "non_conformity",
          entity_id: closed_non_conformity.id,
          reason: closed_non_conformity.closure_notes,
          previous_state: previous_state,
          new_state: non_conformity_state(closed_non_conformity)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{non_conformity: closed_non_conformity}} -> {:ok, closed_non_conformity}
        {:error, :non_conformity, changeset, _changes} -> {:error, changeset}
        {:error, _operation, reason, _changes} -> {:error, reason}
      end
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp control_attrs(entry, attrs) do
    accepted_quantity = Map.get(attrs, "accepted_quantity") || Map.get(attrs, :accepted_quantity)

    with {:ok, accepted_quantity} <- parse_decimal(accepted_quantity),
         :ok <- accepted_not_above_executed(accepted_quantity, entry.quantity) do
      rejected_quantity = Decimal.sub(entry.quantity, accepted_quantity)

      {:ok,
       attrs
       |> put_project_id(entry.project_id)
       |> put_work_item_id(entry.work_item_id)
       |> put_executed_progress_entry_id(entry.id)
       |> put_calculated(:accepted_quantity, accepted_quantity)
       |> put_calculated(:rejected_quantity, rejected_quantity)
       |> put_calculated(:status, status_for(accepted_quantity, rejected_quantity))
       |> normalize_non_conformity_originated()}
    end
  end

  defp parse_decimal(%Decimal{} = value), do: {:ok, value}

  defp parse_decimal(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, ""} -> {:ok, decimal}
      _other -> {:error, :invalid_quantity}
    end
  end

  defp parse_decimal(_value), do: {:error, :invalid_quantity}

  defp accepted_not_above_executed(accepted_quantity, executed_quantity) do
    cond do
      Decimal.lt?(accepted_quantity, 0) -> :ok
      Decimal.lte?(accepted_quantity, executed_quantity) -> :ok
      true -> {:error, :accepted_quantity_exceeds_executed}
    end
  end

  defp status_for(accepted_quantity, rejected_quantity) do
    cond do
      Decimal.eq?(accepted_quantity, 0) -> :rejected
      Decimal.eq?(rejected_quantity, 0) -> :accepted
      true -> :partially_accepted
    end
  end

  defp audit_action(%QualityControl{accepted_quantity: accepted_quantity}) do
    if Decimal.gt?(accepted_quantity, 0), do: :quality_accepted, else: :quality_rejected
  end

  defp non_conformity_attrs(project, work_item, attrs) do
    quality_control_id =
      Map.get(attrs, "quality_control_id") || Map.get(attrs, :quality_control_id)

    with {:ok, attrs} <-
           maybe_put_quality_control_attrs(project, work_item, attrs, quality_control_id),
         {:ok, attrs} <- maybe_put_manual_affected_quantity(attrs) do
      {:ok,
       attrs
       |> put_project_id(project.id)
       |> put_work_item_id(work_item.id)}
    end
  end

  defp maybe_put_quality_control_attrs(_project, _work_item, attrs, value)
       when value in [nil, ""] do
    {:ok, attrs}
  end

  defp maybe_put_quality_control_attrs(project, work_item, attrs, quality_control_id) do
    case quality_control_for_work_item(project, work_item, quality_control_id) do
      %QualityControl{rejected_quantity: rejected_quantity} = control ->
        if Decimal.gt?(rejected_quantity, 0) do
          {:ok,
           attrs
           |> put_attr(:quality_control_id, control.id)
           |> put_attr(:executed_progress_entry_id, control.executed_progress_entry_id)
           |> put_attr(:affected_quantity, rejected_quantity)}
        else
          {:error, :quality_control_without_rejection}
        end

      nil ->
        {:error, :not_found}
    end
  end

  defp maybe_put_manual_affected_quantity(attrs) do
    case Map.get(attrs, "affected_quantity") || Map.get(attrs, :affected_quantity) do
      nil -> {:error, :affected_quantity_required}
      "" -> {:error, :affected_quantity_required}
      %Decimal{} -> {:ok, attrs}
      value -> parse_decimal(value) |> manual_affected_quantity(attrs)
    end
  end

  defp manual_affected_quantity({:ok, affected_quantity}, attrs) do
    {:ok, put_attr(attrs, :affected_quantity, affected_quantity)}
  end

  defp manual_affected_quantity({:error, reason}, _attrs), do: {:error, reason}

  defp work_item_for_project(%Project{id: project_id}, work_item_id) do
    Repo.get_by(WorkItem, id: work_item_id, project_id: project_id)
  end

  defp work_items_belong_to_project(_project, []), do: :ok

  defp work_items_belong_to_project(%Project{id: project_id}, work_item_ids) do
    count =
      Repo.aggregate(
        from(w in WorkItem, where: w.project_id == ^project_id and w.id in ^work_item_ids),
        :count,
        :id
      )

    if count == length(Enum.uniq(work_item_ids)), do: :ok, else: {:error, :not_found}
  end

  defp executed_progress_for_project(%Project{id: project_id}, entry_id) do
    Repo.get_by(ExecutedProgressEntry, id: entry_id, project_id: project_id)
  end

  defp quality_control_for_work_item(project, work_item, quality_control_id) do
    Repo.get_by(QualityControl,
      id: quality_control_id,
      project_id: project.id,
      work_item_id: work_item.id
    )
  end

  defp non_conformity_for_project(%Project{id: project_id}, non_conformity_id) do
    Repo.get_by(NonConformity, id: non_conformity_id, project_id: project_id)
  end

  defp ensure_open(%NonConformity{status: :open}), do: :ok
  defp ensure_open(%NonConformity{status: :closed}), do: {:error, :already_closed}

  defp put_project_id(attrs, project_id), do: put_attr(attrs, :project_id, project_id)
  defp put_work_item_id(attrs, work_item_id), do: put_attr(attrs, :work_item_id, work_item_id)

  defp put_executed_progress_entry_id(attrs, entry_id) do
    put_attr(attrs, :executed_progress_entry_id, entry_id)
  end

  defp put_calculated(attrs, key, value), do: put_attr(attrs, key, value)

  defp put_closed_at(attrs, closed_at), do: put_attr(attrs, :closed_at, closed_at)

  defp put_attr(attrs, key, value) do
    if Enum.any?(Map.keys(attrs), &is_binary/1),
      do: Map.put(attrs, to_string(key), value),
      else: Map.put(attrs, key, value)
  end

  defp normalize_non_conformity_originated(attrs) do
    value =
      Map.get(attrs, "non_conformity_originated") ||
        Map.get(attrs, :non_conformity_originated) ||
        false

    put_attr(attrs, :non_conformity_originated, value)
  end

  defp quality_control_state(control) do
    %{
      "executed_progress_entry_id" => control.executed_progress_entry_id,
      "work_item_id" => control.work_item_id,
      "status" => to_string(control.status),
      "accepted_quantity" => Decimal.to_string(control.accepted_quantity, :normal),
      "rejected_quantity" => Decimal.to_string(control.rejected_quantity, :normal),
      "non_conformity_originated" => control.non_conformity_originated
    }
  end

  defp non_conformity_state(non_conformity) do
    %{
      "work_item_id" => non_conformity.work_item_id,
      "quality_control_id" => non_conformity.quality_control_id,
      "executed_progress_entry_id" => non_conformity.executed_progress_entry_id,
      "defect" => non_conformity.defect,
      "location_sector" => non_conformity.location_sector,
      "responsible_name" => non_conformity.responsible_name,
      "status" => to_string(non_conformity.status),
      "affected_quantity" => Decimal.to_string(non_conformity.affected_quantity, :normal),
      "disposition" => non_conformity.disposition,
      "due_on" => date_to_string(non_conformity.due_on),
      "closed_at" => datetime_to_string(non_conformity.closed_at)
    }
  end

  defp date_to_string(nil), do: nil
  defp date_to_string(%Date{} = date), do: Date.to_iso8601(date)

  defp datetime_to_string(nil), do: nil
  defp datetime_to_string(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)

  defp zero, do: Decimal.new("0.0000")
end
