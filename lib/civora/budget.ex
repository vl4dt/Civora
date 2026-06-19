defmodule Civora.Budget do
  @moduledoc """
  Project-scoped budget structures, beginning with construction work items.
  """

  import Ecto.Query, warn: false

  alias Civora.Accounts.{Scope, User}
  alias Civora.Audit
  alias Civora.Budget.WorkItem
  alias Civora.Projects
  alias Civora.Projects.{Project, ProjectPhase}
  alias Civora.Repo

  def change_work_item(%WorkItem{} = work_item, attrs \\ %{}) do
    WorkItem.changeset(work_item, attrs)
  end

  def list_work_items(%Scope{} = scope, %Project{} = project) do
    with true <- Projects.authorized?(scope, project, :view) do
      items =
        from(w in WorkItem,
          where: w.project_id == ^project.id,
          join: phase in assoc(w, :project_phase),
          preload: [project_phase: phase],
          order_by: [asc: w.id]
        )
        |> Repo.all()

      {:ok, items}
    else
      false -> {:error, :unauthorized}
    end
  end

  def get_work_item(%Scope{} = scope, %Project{} = project, id) do
    with true <- Projects.authorized?(scope, project, :view),
         %WorkItem{} = item <-
           Repo.one(
             from(w in WorkItem,
               where: w.id == ^id and w.project_id == ^project.id,
               preload: :project_phase
             )
           ) do
      {:ok, item}
    else
      false -> {:error, :not_found}
      nil -> {:error, :not_found}
    end
  end

  def create_work_item(
        %Scope{user: %User{} = actor} = scope,
        %Project{} = project,
        attrs
      ) do
    with true <- Projects.authorized?(scope, project, :manage_budget),
         %ProjectPhase{} <- phase_for_project(project, phase_id(attrs)) do
      attrs = put_project_id(attrs, project.id)

      Ecto.Multi.new()
      |> Ecto.Multi.insert(:work_item, WorkItem.changeset(%WorkItem{}, attrs))
      |> Ecto.Multi.insert(:audit_event, fn %{work_item: item} ->
        Audit.event_changeset(actor, project, %{
          action: :work_item_created,
          entity_type: "work_item",
          entity_id: item.id,
          new_state: work_item_state(item)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{work_item: item}} -> {:ok, Repo.preload(item, :project_phase)}
        {:error, :work_item, changeset, _changes} -> {:error, changeset}
      end
    else
      false -> {:error, :unauthorized}
      nil -> {:error, invalid_phase_changeset(attrs, project.id)}
    end
  end

  defp phase_for_project(%Project{id: project_id}, phase_id) when phase_id not in [nil, ""] do
    Repo.get_by(ProjectPhase, id: phase_id, project_id: project_id)
  end

  defp phase_for_project(_project, _phase_id), do: nil

  defp phase_id(attrs), do: attrs["project_phase_id"] || attrs[:project_phase_id]

  defp put_project_id(attrs, project_id) do
    if Enum.any?(Map.keys(attrs), &is_binary/1),
      do: Map.put(attrs, "project_id", project_id),
      else: Map.put(attrs, :project_id, project_id)
  end

  defp invalid_phase_changeset(attrs, project_id) do
    %WorkItem{}
    |> WorkItem.changeset(put_project_id(attrs, project_id))
    |> Ecto.Changeset.add_error(:project_phase_id, "is invalid")
  end

  defp work_item_state(item) do
    %{
      "project_phase_id" => item.project_phase_id,
      "unit" => item.unit,
      "quantity" => Decimal.to_string(item.quantity, :normal),
      "description" => item.description
    }
  end
end
