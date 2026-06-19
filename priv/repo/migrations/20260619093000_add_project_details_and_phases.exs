defmodule Civora.Repo.Migrations.AddProjectDetailsAndPhases do
  use Ecto.Migration

  @project_statuses ~w(planificacion activo pausado cerrado cancelado)
  @phase_types ~w(diseno presupuesto planificacion construccion supervision cierre)

  def change do
    alter table(:projects) do
      add :client_reference, :string, null: false, default: "Sin referencia"
      add :status, :string, null: false, default: "planificacion"
      add :description, :text, null: false, default: "Sin descripcion"
    end

    create constraint(:projects, :projects_status_check,
             check: "status IN (#{quoted_values(@project_statuses)})"
           )

    create table(:project_phases) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :phase_type, :string, null: false
      add :description, :text, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:project_phases, [:project_id, :name])

    create constraint(:project_phases, :project_phases_type_check,
             check: "phase_type IN (#{quoted_values(@phase_types)})"
           )
  end

  defp quoted_values(values), do: Enum.map_join(values, ", ", &"'#{&1}'")
end
