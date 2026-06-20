defmodule Civora.Budget.ProjectBudgetLine do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.{
    BudgetedPerformanceSheet,
    ProjectBudget,
    ProjectBudgetLineResource,
    WorkItem
  }

  schema "project_budget_lines" do
    field :phase_name, :string
    field :description, :string
    field :unit, :string
    field :quantity, :decimal
    field :sheet_name, :string
    field :sheet_description, :string
    field :sheet_unit, :string
    field :productivity, :decimal
    field :waste_percentage, :decimal

    belongs_to :project_budget, ProjectBudget
    belongs_to :source_work_item, WorkItem
    belongs_to :source_budgeted_performance_sheet, BudgetedPerformanceSheet
    has_many :resources, ProjectBudgetLineResource

    timestamps(type: :utc_datetime)
  end

  def changeset(line, attrs) do
    line
    |> cast(attrs, [
      :project_budget_id,
      :source_work_item_id,
      :source_budgeted_performance_sheet_id,
      :phase_name,
      :description,
      :unit,
      :quantity,
      :sheet_name,
      :sheet_description,
      :sheet_unit,
      :productivity,
      :waste_percentage
    ])
    |> validate_required([
      :project_budget_id,
      :source_work_item_id,
      :phase_name,
      :description,
      :unit,
      :quantity
    ])
    |> validate_number(:quantity, greater_than: 0)
    |> foreign_key_constraint(:project_budget_id)
    |> foreign_key_constraint(:source_work_item_id)
    |> foreign_key_constraint(:source_budgeted_performance_sheet_id)
    |> unique_constraint([:project_budget_id, :source_work_item_id],
      name: :project_budget_lines_budget_work_item_index
    )
    |> check_constraint(:quantity, name: :project_budget_lines_quantity_positive)
  end
end
