defmodule Civora.Repo.Migrations.CreateExecutedProgressEntries do
  use Ecto.Migration

  def up do
    create unique_index(:work_activities, [:id, :work_item_id, :project_id],
             name: :work_activities_id_work_item_project_id_index
           )

    create table(:executed_progress_entries) do
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :work_item_id, references(:work_items, on_delete: :restrict), null: false
      add :work_activity_id, references(:work_activities, on_delete: :restrict), null: false
      add :quantity, :decimal, precision: 18, scale: 4, null: false
      add :location_sector, :string, null: false
      add :payable, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:executed_progress_entries, [:project_id])
    create index(:executed_progress_entries, [:work_item_id])
    create index(:executed_progress_entries, [:work_activity_id])

    execute """
            ALTER TABLE executed_progress_entries
            ADD CONSTRAINT executed_progress_entries_work_item_belongs_to_project
            FOREIGN KEY (work_item_id, project_id)
            REFERENCES work_items(id, project_id)
            """,
            "ALTER TABLE executed_progress_entries DROP CONSTRAINT executed_progress_entries_work_item_belongs_to_project"

    execute """
            ALTER TABLE executed_progress_entries
            ADD CONSTRAINT executed_progress_entries_activity_belongs_to_work_item
            FOREIGN KEY (work_activity_id, work_item_id, project_id)
            REFERENCES work_activities(id, work_item_id, project_id)
            """,
            "ALTER TABLE executed_progress_entries DROP CONSTRAINT executed_progress_entries_activity_belongs_to_work_item"

    create constraint(:executed_progress_entries, :executed_progress_entries_quantity_positive,
             check: "quantity > 0"
           )

    create constraint(
             :executed_progress_entries,
             :executed_progress_entries_location_sector_length,
             check: "char_length(location_sector) BETWEEN 2 AND 160"
           )

    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check",
            """
            ALTER TABLE audit_events
            ADD CONSTRAINT audit_events_action_check
            CHECK (action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'budget_approved', 'quality_accepted', 'estimate_created'))
            """

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'executed_progress_created', 'budget_approved', 'quality_accepted', 'estimate_created')"
           )
  end

  def down do
    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check"

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'budget_approved', 'quality_accepted', 'estimate_created')"
           )

    drop table(:executed_progress_entries)

    drop index(:work_activities, [:id, :work_item_id, :project_id],
           name: :work_activities_id_work_item_project_id_index
         )
  end
end
