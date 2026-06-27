defmodule Civora.Execution do
  @moduledoc """
  Project execution planning and field progress structures.
  """

  import Ecto.Query, warn: false

  alias Civora.Accounts.{Scope, User}
  alias Civora.Audit
  alias Civora.Budget.WorkItem
  alias Civora.Execution.WorkActivity
  alias Civora.Projects
  alias Civora.Projects.Project
  alias Civora.Repo

  def change_work_activity(%WorkActivity{} = activity, attrs \\ %{}) do
    WorkActivity.changeset(activity, attrs)
  end

  def list_work_activities(%Scope{} = scope, %Project{} = project) do
    with true <- Projects.authorized?(scope, project, :view) do
      activities =
        from(a in WorkActivity,
          where: a.project_id == ^project.id,
          join: w in assoc(a, :work_item),
          preload: [work_item: w],
          order_by: [asc: a.work_item_id, asc: a.location_sector, asc: a.id]
        )
        |> Repo.all()

      {:ok, activities}
    else
      false -> {:error, :unauthorized}
    end
  end

  def list_work_item_activities(%Scope{} = scope, %Project{} = project, %WorkItem{} = work_item) do
    with true <- Projects.authorized?(scope, project, :view),
         %WorkItem{} <- work_item_for_project(project, work_item.id) do
      activities =
        from(a in WorkActivity,
          where: a.project_id == ^project.id and a.work_item_id == ^work_item.id,
          order_by: [asc: a.location_sector, asc: a.id]
        )
        |> Repo.all()

      {:ok, activities}
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
    end
  end

  def get_work_activity(%Scope{} = scope, %Project{} = project, id) do
    with true <- Projects.authorized?(scope, project, :view) do
      from(a in WorkActivity,
        where: a.id == ^id and a.project_id == ^project.id,
        preload: :work_item
      )
      |> Repo.one()
      |> case do
        nil -> {:error, :not_found}
        activity -> {:ok, activity}
      end
    else
      false -> {:error, :unauthorized}
    end
  end

  def create_work_activity(
        %Scope{user: %User{} = actor} = scope,
        %Project{} = project,
        %WorkItem{} = work_item,
        attrs
      ) do
    with true <- Projects.authorized?(scope, project, :manage_activities),
         %WorkItem{} <- work_item_for_project(project, work_item.id) do
      attrs =
        attrs
        |> put_project_id(project.id)
        |> put_work_item_id(work_item.id)

      Ecto.Multi.new()
      |> Ecto.Multi.insert(:activity, WorkActivity.changeset(%WorkActivity{}, attrs))
      |> Ecto.Multi.insert(:audit_event, fn %{activity: activity} ->
        Audit.event_changeset(actor, project, %{
          action: :work_activity_created,
          entity_type: "work_activity",
          entity_id: activity.id,
          new_state: work_activity_state(activity)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{activity: activity}} -> {:ok, activity}
        {:error, :activity, changeset, _changes} -> {:error, changeset}
        {:error, _operation, reason, _changes} -> {:error, reason}
      end
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
    end
  end

  defp work_item_for_project(%Project{id: project_id}, work_item_id) do
    Repo.get_by(WorkItem, id: work_item_id, project_id: project_id)
  end

  defp put_project_id(attrs, project_id) do
    if Enum.any?(Map.keys(attrs), &is_binary/1),
      do: Map.put(attrs, "project_id", project_id),
      else: Map.put(attrs, :project_id, project_id)
  end

  defp put_work_item_id(attrs, work_item_id) do
    if Enum.any?(Map.keys(attrs), &is_binary/1),
      do: Map.put(attrs, "work_item_id", work_item_id),
      else: Map.put(attrs, :work_item_id, work_item_id)
  end

  defp work_activity_state(activity) do
    %{
      "work_item_id" => activity.work_item_id,
      "location_sector" => activity.location_sector,
      "description" => activity.description
    }
  end
end
