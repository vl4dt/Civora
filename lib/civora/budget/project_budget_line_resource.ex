defmodule Civora.Budget.ProjectBudgetLineResource do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.{PerformanceSheetResource, ProjectBudgetLine}

  schema "project_budget_line_resources" do
    field :category, Ecto.Enum, values: PerformanceSheetResource.categories()
    field :name, :string
    field :unit, :string
    field :quantity, :decimal

    belongs_to :project_budget_line, ProjectBudgetLine

    timestamps(type: :utc_datetime)
  end

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:project_budget_line_id, :category, :name, :unit, :quantity])
    |> validate_required([:project_budget_line_id, :category, :name, :unit, :quantity])
    |> validate_number(:quantity, greater_than: 0)
    |> foreign_key_constraint(:project_budget_line_id)
    |> check_constraint(:category, name: :project_budget_line_resources_category_check)
    |> check_constraint(:quantity, name: :project_budget_line_resources_quantity_positive)
  end
end
