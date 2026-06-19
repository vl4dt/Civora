defmodule Civora.Repo.Migrations.CreateWorkItems do
  use Ecto.Migration

  def change do
    create unique_index(:project_phases, [:id, :project_id],
             name: :project_phases_id_project_id_index
           )

    create table(:work_items) do
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :project_phase_id, references(:project_phases, on_delete: :restrict), null: false
      add :unit, :string, null: false
      add :quantity, :decimal, precision: 18, scale: 4, null: false
      add :description, :text, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:work_items, [:project_id, :project_phase_id])

    create constraint(:work_items, :work_items_quantity_positive, check: "quantity > 0")

    execute """
            ALTER TABLE work_items
            ADD CONSTRAINT work_items_phase_belongs_to_project
            FOREIGN KEY (project_phase_id, project_id)
            REFERENCES project_phases(id, project_id)
            ON DELETE RESTRICT
            """,
            "ALTER TABLE work_items DROP CONSTRAINT work_items_phase_belongs_to_project"

    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check",
            """
            ALTER TABLE audit_events
            ADD CONSTRAINT audit_events_action_check
            CHECK (action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'budget_approved', 'quality_accepted', 'estimate_created'))
            """

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'budget_approved', 'quality_accepted', 'estimate_created')"
           )
  end
end
