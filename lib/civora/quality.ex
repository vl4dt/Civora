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
  alias Civora.Quality.QualityControl
  alias Civora.Repo

  def change_quality_control(%QualityControl{} = control, attrs \\ %{}) do
    QualityControl.changeset(control, attrs)
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

  defp work_item_for_project(%Project{id: project_id}, work_item_id) do
    Repo.get_by(WorkItem, id: work_item_id, project_id: project_id)
  end

  defp executed_progress_for_project(%Project{id: project_id}, entry_id) do
    Repo.get_by(ExecutedProgressEntry, id: entry_id, project_id: project_id)
  end

  defp put_project_id(attrs, project_id), do: put_attr(attrs, :project_id, project_id)
  defp put_work_item_id(attrs, work_item_id), do: put_attr(attrs, :work_item_id, work_item_id)

  defp put_executed_progress_entry_id(attrs, entry_id) do
    put_attr(attrs, :executed_progress_entry_id, entry_id)
  end

  defp put_calculated(attrs, key, value), do: put_attr(attrs, key, value)

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
end
