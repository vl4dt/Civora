defmodule Civora.Budget.WorkItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Projects.{Project, ProjectPhase}

  schema "work_items" do
    field :unit, :string
    field :quantity, :decimal
    field :description, :string

    belongs_to :project, Project
    belongs_to :project_phase, ProjectPhase
    has_one :budgeted_performance_sheet, Civora.Budget.BudgetedPerformanceSheet

    timestamps(type: :utc_datetime)
  end

  def changeset(work_item, attrs) do
    work_item
    |> cast(attrs, [:project_id, :project_phase_id, :unit, :quantity, :description])
    |> validate_required([:project_id, :project_phase_id, :unit, :quantity, :description])
    |> validate_length(:unit, min: 1, max: 40)
    |> validate_length(:description, min: 2, max: 2_000)
    |> validate_number(:quantity, greater_than: 0)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:project_phase_id)
    |> check_constraint(:quantity, name: :work_items_quantity_positive)
    |> foreign_key_constraint(:project_phase_id, name: :work_items_phase_belongs_to_project)
  end
end
