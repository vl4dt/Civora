defmodule Civora.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:planificacion, :activo, :pausado, :cerrado, :cancelado]

  schema "projects" do
    field :name, :string
    field :client_reference, :string
    field :status, Ecto.Enum, values: @statuses, default: :planificacion
    field :description, :string

    has_many :assignments, Civora.Projects.ProjectAssignment
    has_many :phases, Civora.Projects.ProjectPhase
    has_many :work_items, Civora.Budget.WorkItem
    has_many :subcontracts, Civora.Subcontracts.Subcontract
    has_many :work_activities, Civora.Execution.WorkActivity
    has_many :executed_progress_entries, Civora.Execution.ExecutedProgressEntry
    has_one :project_budget, Civora.Budget.ProjectBudget

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :client_reference, :status, :description])
    |> validate_required([:name, :client_reference, :status, :description])
    |> validate_length(:name, min: 2, max: 160)
    |> validate_length(:client_reference, min: 2, max: 160)
    |> validate_length(:description, min: 2, max: 2_000)
    |> check_constraint(:status, name: :projects_status_check)
  end
end
