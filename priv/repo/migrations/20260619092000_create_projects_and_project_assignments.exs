defmodule Civora.Repo.Migrations.CreateProjectsAndProjectAssignments do
  use Ecto.Migration

  @roles ~w(administrador director_proyecto presupuesto calidad finanzas consulta)

  def change do
    create table(:projects) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:project_assignments) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :role, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:project_assignments, [:project_id, :user_id])
    create index(:project_assignments, [:user_id])

    create constraint(:project_assignments, :project_assignments_role_check,
             check: "role IN (#{Enum.map_join(@roles, ", ", &"'#{&1}'")})"
           )
  end
end
