defmodule Civora.Projects.ProjectAssignment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Accounts.User
  alias Civora.Projects.Project

  @roles [
    :administrador,
    :director_proyecto,
    :presupuesto,
    :calidad,
    :finanzas,
    :consulta
  ]

  schema "project_assignments" do
    field :role, Ecto.Enum, values: @roles

    belongs_to :project, Project
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def roles, do: @roles

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:project_id, :user_id, :role])
    |> validate_required([:project_id, :user_id, :role])
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:project_id, :user_id])
    |> check_constraint(:role, name: :project_assignments_role_check)
  end

  def role_changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> check_constraint(:role, name: :project_assignments_role_check)
  end
end
