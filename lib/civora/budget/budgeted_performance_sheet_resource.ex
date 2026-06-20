defmodule Civora.Budget.BudgetedPerformanceSheetResource do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.{BudgetedPerformanceSheet, PerformanceSheetResource}

  schema "budgeted_performance_sheet_resources" do
    field :category, Ecto.Enum, values: PerformanceSheetResource.categories()
    field :name, :string
    field :unit, :string
    field :quantity, :decimal

    belongs_to :budgeted_performance_sheet, BudgetedPerformanceSheet

    timestamps(type: :utc_datetime)
  end

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:category, :name, :unit, :quantity])
    |> validate_required([:category, :name, :unit, :quantity])
    |> validate_length(:name, min: 2, max: 160)
    |> validate_length(:unit, min: 1, max: 40)
    |> validate_number(:quantity, greater_than: 0)
    |> check_constraint(:category,
      name: :budgeted_performance_sheet_resources_category_check
    )
    |> check_constraint(:quantity,
      name: :budgeted_performance_sheet_resources_quantity_positive
    )
  end
end
