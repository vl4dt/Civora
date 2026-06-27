defmodule Civora.Repo.Migrations.CreateWorkActivities do
  use Ecto.Migration

  def up do
    create table(:work_activities) do
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :work_item_id, references(:work_items, on_delete: :restrict), null: false
      add :location_sector, :string, null: false
      add :description, :text, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:work_activities, [:project_id])
    create index(:work_activities, [:work_item_id])

    execute """
            ALTER TABLE work_activities
            ADD CONSTRAINT work_activities_work_item_belongs_to_project
            FOREIGN KEY (work_item_id, project_id)
            REFERENCES work_items(id, project_id)
            """,
            "ALTER TABLE work_activities DROP CONSTRAINT work_activities_work_item_belongs_to_project"

    create constraint(:work_activities, :work_activities_location_sector_length,
             check: "char_length(location_sector) BETWEEN 2 AND 160"
           )

    create constraint(:work_activities, :work_activities_description_length,
             check: "char_length(description) BETWEEN 2 AND 2000"
           )

    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check",
            """
            ALTER TABLE audit_events
            ADD CONSTRAINT audit_events_action_check
            CHECK (action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'budget_approved', 'quality_accepted', 'estimate_created'))
            """

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'budget_approved', 'quality_accepted', 'estimate_created')"
           )
  end

  def down do
    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check"

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'budget_approved', 'quality_accepted', 'estimate_created')"
           )

    drop table(:work_activities)
  end
end
