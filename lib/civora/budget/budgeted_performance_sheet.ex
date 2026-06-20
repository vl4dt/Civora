defmodule Civora.Budget.BudgetedPerformanceSheet do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.{
    BudgetedPerformanceSheetResource,
    PerformanceSheet,
    WorkItem
  }

  alias Civora.Projects.Project

  schema "budgeted_performance_sheets" do
    field :name, :string
    field :description, :string
    field :unit, :string
    field :productivity, :decimal
    field :waste_percentage, :decimal

    belongs_to :project, Project
    belongs_to :work_item, WorkItem
    belongs_to :source_performance_sheet, PerformanceSheet

    has_many :resources, BudgetedPerformanceSheetResource, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def changeset(sheet, attrs) do
    sheet
    |> cast(attrs, [
      :project_id,
      :work_item_id,
      :source_performance_sheet_id,
      :name,
      :description,
      :unit,
      :productivity,
      :waste_percentage
    ])
    |> validate_required([
      :project_id,
      :work_item_id,
      :source_performance_sheet_id,
      :name,
      :description,
      :unit
    ])
    |> validate_length(:name, min: 2, max: 160)
    |> validate_length(:description, min: 2, max: 2_000)
    |> validate_length(:unit, min: 1, max: 40)
    |> validate_number(:productivity, greater_than: 0)
    |> validate_number(:waste_percentage, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:work_item_id)
    |> foreign_key_constraint(:source_performance_sheet_id)
    |> foreign_key_constraint(:work_item_id,
      name: :budgeted_performance_sheets_work_item_belongs_to_project
    )
    |> unique_constraint(:work_item_id)
    |> check_constraint(:productivity,
      name: :budgeted_performance_sheets_productivity_positive
    )
    |> check_constraint(:waste_percentage,
      name: :budgeted_performance_sheets_waste_percentage_range
    )
    |> cast_assoc(:resources,
      with: &BudgetedPerformanceSheetResource.changeset/2,
      required: true
    )
  end
end
