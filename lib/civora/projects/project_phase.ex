defmodule Civora.Projects.ProjectPhase do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Projects.Project

  @types [:diseno, :presupuesto, :planificacion, :construccion, :supervision, :cierre]

  schema "project_phases" do
    field :name, :string
    field :phase_type, Ecto.Enum, values: @types
    field :description, :string

    belongs_to :project, Project

    timestamps(type: :utc_datetime)
  end

  def types, do: @types

  def changeset(phase, attrs) do
    phase
    |> cast(attrs, [:project_id, :name, :phase_type, :description])
    |> validate_required([:project_id, :name, :phase_type, :description])
    |> validate_length(:name, min: 2, max: 160)
    |> validate_length(:description, min: 2, max: 2_000)
    |> foreign_key_constraint(:project_id)
    |> unique_constraint([:project_id, :name])
    |> check_constraint(:phase_type, name: :project_phases_type_check)
  end
end
