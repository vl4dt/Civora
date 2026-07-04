defmodule Civora.Reports do
  @moduledoc """
  Read models for internal project reporting.
  """

  import Ecto.Query, warn: false

  alias Civora.Accounts.Scope
  alias Civora.Budget
  alias Civora.Budget.ProjectBudget
  alias Civora.Projects
  alias Civora.Projects.Project
  alias Civora.Quality
  alias Civora.Quality.NonConformity
  alias Civora.Repo
  alias Civora.Subcontracts
  alias Civora.Subcontracts.SubcontractEstimate

  def get_internal_project_report(%Scope{} = scope, %Project{} = project) do
    with true <- Projects.authorized?(scope, project, :view),
         {:ok, budget} <- Budget.get_project_budget(scope, project),
         {:ok, work_items} <- Budget.list_work_items(scope, project),
         {:ok, progress_by_work_item_id} <-
           Quality.list_work_items_payable_progress(scope, project, work_items),
         {:ok, cost_summary} <- Subcontracts.get_project_cost_summary(scope, project) do
      {:ok,
       %{
         budget: budget,
         budget_lines: approved_budget_lines(budget),
         work_item_progress:
           work_item_progress_rows(work_items, progress_by_work_item_id, budget),
         open_non_conformities: open_non_conformities(project),
         estimates: estimates(project),
         cost_summary: cost_summary
       }}
    else
      false -> {:error, :unauthorized}
      {:error, reason} -> {:error, reason}
    end
  end

  defp approved_budget_lines(%ProjectBudget{status: :approved, lines: lines}), do: lines
  defp approved_budget_lines(_budget), do: []

  defp work_item_progress_rows(work_items, progress_by_work_item_id, budget) do
    budget_lines_by_work_item_id =
      budget
      |> approved_budget_lines()
      |> Map.new(&{&1.source_work_item_id, &1})

    Enum.map(work_items, fn work_item ->
      %{
        work_item: work_item,
        budget_line: Map.get(budget_lines_by_work_item_id, work_item.id),
        progress: Map.fetch!(progress_by_work_item_id, work_item.id)
      }
    end)
  end

  defp open_non_conformities(%Project{} = project) do
    from(n in NonConformity,
      where: n.project_id == ^project.id and n.status == :open,
      preload: [:work_item, :quality_control, :executed_progress_entry],
      order_by: [asc: n.due_on, desc: n.inserted_at, desc: n.id]
    )
    |> Repo.all()
  end

  defp estimates(%Project{} = project) do
    from(e in SubcontractEstimate,
      where: e.project_id == ^project.id,
      preload: [subcontract: :counterparty, lines: :work_item],
      order_by: [desc: e.inserted_at, desc: e.id]
    )
    |> Repo.all()
  end
end
