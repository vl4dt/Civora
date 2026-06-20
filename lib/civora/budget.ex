defmodule Civora.Budget do
  @moduledoc """
  Project-scoped budget structures, beginning with construction work items.
  """

  import Ecto.Query, warn: false

  alias Civora.Accounts.{Scope, User}
  alias Civora.Audit

  alias Civora.Budget.{
    BudgetedPerformanceSheet,
    PerformanceSheet,
    PerformanceSheetResource,
    ProjectBudget,
    ProjectBudgetLine,
    ProjectBudgetLineResource,
    WorkItem
  }

  alias Civora.Projects
  alias Civora.Projects.{Project, ProjectPhase}
  alias Civora.Projects.ProjectAssignment
  alias Civora.Repo

  def change_work_item(%WorkItem{} = work_item, attrs \\ %{}) do
    WorkItem.changeset(work_item, attrs)
  end

  def change_performance_sheet(%PerformanceSheet{} = sheet, attrs \\ %{}) do
    PerformanceSheet.changeset(sheet, attrs)
  end

  def list_performance_sheets(%Scope{user: %User{}}) do
    from(s in PerformanceSheet,
      preload: :resources,
      order_by: [asc: s.name, asc: s.id]
    )
    |> Repo.all()
  end

  def get_performance_sheet(%Scope{user: %User{}}, id) do
    case Repo.one(from(s in PerformanceSheet, where: s.id == ^id, preload: :resources)) do
      %PerformanceSheet{} = sheet -> {:ok, sheet}
      nil -> {:error, :not_found}
    end
  end

  def create_performance_sheet(%Scope{user: %User{}} = scope, attrs) do
    with true <- can_manage_performance_sheets?(scope) do
      %PerformanceSheet{}
      |> PerformanceSheet.changeset(attrs)
      |> Repo.insert()
    else
      false -> {:error, :unauthorized}
    end
  end

  def can_manage_performance_sheets?(%Scope{user: %User{id: user_id}}) do
    Repo.exists?(
      from(a in ProjectAssignment,
        where:
          a.user_id == ^user_id and
            a.role in [:administrador, :director_proyecto, :presupuesto]
      )
    )
  end

  def can_manage_performance_sheets?(_scope), do: false

  def resource_categories, do: PerformanceSheetResource.categories()

  def resource_category_label(:material), do: "Material"
  def resource_category_label(:labor), do: "Mano de obra"

  def get_project_budget(%Scope{} = scope, %Project{} = project) do
    with true <- Projects.authorized?(scope, project, :view) do
      budget =
        Repo.one(
          from(b in ProjectBudget,
            where: b.project_id == ^project.id,
            preload: [approved_by: [], lines: ^project_budget_lines_query()]
          )
        )

      {:ok, budget}
    else
      false -> {:error, :unauthorized}
    end
  end

  def create_project_budget(%Scope{} = scope, %Project{} = project) do
    with true <- Projects.authorized?(scope, project, :manage_budget) do
      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :project_budget,
        ProjectBudget.create_changeset(%ProjectBudget{}, %{project_id: project.id})
      )
      |> Ecto.Multi.run(:lines, fn repo, %{project_budget: budget} ->
        insert_project_budget_lines(repo, budget, project)
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{project_budget: budget}} -> {:ok, preload_project_budget(budget)}
        {:error, :project_budget, changeset, _changes} -> {:error, changeset}
        {:error, :lines, reason, _changes} -> {:error, reason}
      end
    else
      false -> {:error, :unauthorized}
    end
  end

  def approve_project_budget(
        %Scope{user: %User{} = actor} = scope,
        %Project{} = project,
        %ProjectBudget{} = budget
      ) do
    with true <- Projects.authorized?(scope, project, :manage_budget) do
      approved_at = DateTime.utc_now() |> DateTime.truncate(:second)

      Ecto.Multi.new()
      |> Ecto.Multi.run(:locked_budget, fn repo, _changes ->
        case repo.one(
               from(b in ProjectBudget,
                 where: b.id == ^budget.id and b.project_id == ^project.id,
                 lock: "FOR UPDATE"
               )
             ) do
          %ProjectBudget{status: :draft} = stored -> {:ok, stored}
          %ProjectBudget{status: :approved} -> {:error, :already_approved}
          nil -> {:error, :not_found}
        end
      end)
      |> Ecto.Multi.update(:approved_budget, fn %{locked_budget: stored} ->
        ProjectBudget.approval_changeset(stored, actor.id, approved_at)
      end)
      |> Ecto.Multi.insert(:audit_event, fn %{approved_budget: approved} ->
        Audit.event_changeset(actor, project, %{
          action: :budget_approved,
          entity_type: "project_budget",
          entity_id: approved.id,
          previous_state: %{"status" => "draft"},
          new_state: project_budget_state(approved)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{approved_budget: approved}} -> {:ok, preload_project_budget(approved)}
        {:error, :locked_budget, reason, _changes} -> {:error, reason}
        {:error, :approved_budget, changeset, _changes} -> {:error, changeset}
      end
    else
      false -> {:error, :unauthorized}
    end
  end

  def budget_editable?(%Project{id: project_id}) do
    not Repo.exists?(
      from(b in ProjectBudget, where: b.project_id == ^project_id and b.status == :approved)
    )
  end

  def change_budgeted_performance_sheet(
        %BudgetedPerformanceSheet{} = sheet,
        attrs \\ %{}
      ) do
    BudgetedPerformanceSheet.changeset(sheet, attrs)
  end

  def get_budgeted_performance_sheet_for_work_item(
        %Scope{} = scope,
        %Project{} = project,
        %WorkItem{} = work_item
      ) do
    with true <- Projects.authorized?(scope, project, :view),
         %WorkItem{} <- work_item_for_project(project, work_item.id) do
      sheet =
        Repo.one(
          from(s in BudgetedPerformanceSheet,
            where: s.project_id == ^project.id and s.work_item_id == ^work_item.id,
            preload: [:source_performance_sheet, :resources]
          )
        )

      {:ok, sheet}
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
    end
  end

  def create_budgeted_performance_sheet(
        %Scope{} = scope,
        %Project{} = project,
        %WorkItem{} = work_item,
        source_id
      ) do
    with true <- Projects.authorized?(scope, project, :manage_budget),
         :ok <- ensure_budget_editable(project),
         %WorkItem{} <- work_item_for_project(project, work_item.id),
         %PerformanceSheet{} = source <- performance_sheet_with_resources(source_id) do
      source
      |> budgeted_sheet_snapshot_attrs(project.id, work_item.id)
      |> then(&BudgetedPerformanceSheet.changeset(%BudgetedPerformanceSheet{}, &1))
      |> Repo.insert()
      |> preload_budgeted_sheet_result()
    else
      false -> {:error, :unauthorized}
      {:error, :budget_approved} = error -> error
      nil -> {:error, :not_found}
    end
  end

  def update_budgeted_performance_sheet(
        %Scope{} = scope,
        %Project{} = project,
        %BudgetedPerformanceSheet{} = sheet,
        attrs
      ) do
    with true <- Projects.authorized?(scope, project, :manage_budget),
         :ok <- ensure_budget_editable(project),
         %BudgetedPerformanceSheet{} = stored <- budgeted_sheet_for_project(project, sheet.id) do
      stored
      |> BudgetedPerformanceSheet.changeset(attrs)
      |> Repo.update()
      |> preload_budgeted_sheet_result()
    else
      false -> {:error, :unauthorized}
      {:error, :budget_approved} = error -> error
      nil -> {:error, :not_found}
    end
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
         :ok <- ensure_budget_editable(project),
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
      {:error, :budget_approved} = error -> error
      nil -> {:error, invalid_phase_changeset(attrs, project.id)}
    end
  end

  defp phase_for_project(%Project{id: project_id}, phase_id) when phase_id not in [nil, ""] do
    Repo.get_by(ProjectPhase, id: phase_id, project_id: project_id)
  end

  defp phase_for_project(_project, _phase_id), do: nil

  defp work_item_for_project(%Project{id: project_id}, work_item_id) do
    Repo.get_by(WorkItem, id: work_item_id, project_id: project_id)
  end

  defp performance_sheet_with_resources(source_id) do
    case Repo.get(PerformanceSheet, source_id) do
      %PerformanceSheet{} = source -> Repo.preload(source, :resources)
      nil -> nil
    end
  end

  defp insert_project_budget_lines(repo, budget, project) do
    items =
      from(w in WorkItem,
        where: w.project_id == ^project.id,
        order_by: [asc: w.id],
        preload: [:project_phase, budgeted_performance_sheet: :resources]
      )
      |> repo.all()

    if items == [] do
      {:error, :no_work_items}
    else
      Enum.reduce_while(items, {:ok, []}, fn item, {:ok, lines} ->
        with {:ok, line} <-
               %ProjectBudgetLine{}
               |> ProjectBudgetLine.changeset(project_budget_line_attrs(budget, item))
               |> repo.insert(),
             {:ok, _resources} <- insert_project_budget_line_resources(repo, line, item) do
          {:cont, {:ok, [line | lines]}}
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  defp insert_project_budget_line_resources(repo, line, item) do
    resources =
      case item.budgeted_performance_sheet do
        %BudgetedPerformanceSheet{resources: resources} -> resources
        nil -> []
      end

    Enum.reduce_while(resources, {:ok, []}, fn resource, {:ok, copied} ->
      attrs = %{
        project_budget_line_id: line.id,
        category: resource.category,
        name: resource.name,
        unit: resource.unit,
        quantity: resource.quantity
      }

      case repo.insert(ProjectBudgetLineResource.changeset(%ProjectBudgetLineResource{}, attrs)) do
        {:ok, inserted} -> {:cont, {:ok, [inserted | copied]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
  end

  defp project_budget_line_attrs(budget, item) do
    sheet = item.budgeted_performance_sheet

    %{
      project_budget_id: budget.id,
      source_work_item_id: item.id,
      source_budgeted_performance_sheet_id: sheet && sheet.id,
      phase_name: item.project_phase.name,
      description: item.description,
      unit: item.unit,
      quantity: item.quantity,
      sheet_name: sheet && sheet.name,
      sheet_description: sheet && sheet.description,
      sheet_unit: sheet && sheet.unit,
      productivity: sheet && sheet.productivity,
      waste_percentage: sheet && sheet.waste_percentage
    }
  end

  defp project_budget_lines_query do
    from(l in ProjectBudgetLine, order_by: [asc: l.id], preload: :resources)
  end

  defp preload_project_budget(budget) do
    Repo.preload(budget, [approved_by: [], lines: project_budget_lines_query()], force: true)
  end

  defp project_budget_state(budget) do
    %{
      "status" => Atom.to_string(budget.status),
      "approved_at" => DateTime.to_iso8601(budget.approved_at),
      "approved_by_id" => budget.approved_by_id
    }
  end

  defp ensure_budget_editable(project) do
    if budget_editable?(project), do: :ok, else: {:error, :budget_approved}
  end

  defp budgeted_sheet_for_project(%Project{id: project_id}, sheet_id) do
    Repo.one(
      from(s in BudgetedPerformanceSheet,
        where: s.id == ^sheet_id and s.project_id == ^project_id,
        preload: :resources
      )
    )
  end

  defp budgeted_sheet_snapshot_attrs(source, project_id, work_item_id) do
    %{
      project_id: project_id,
      work_item_id: work_item_id,
      source_performance_sheet_id: source.id,
      name: source.name,
      description: source.description,
      unit: source.unit,
      productivity: source.productivity,
      waste_percentage: source.waste_percentage,
      resources:
        Enum.map(source.resources, fn resource ->
          %{
            category: resource.category,
            name: resource.name,
            unit: resource.unit,
            quantity: resource.quantity
          }
        end)
    }
  end

  defp preload_budgeted_sheet_result({:ok, sheet}) do
    {:ok, Repo.preload(sheet, [:source_performance_sheet, :resources])}
  end

  defp preload_budgeted_sheet_result(error), do: error

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
