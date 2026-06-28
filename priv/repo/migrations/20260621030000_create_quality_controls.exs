defmodule Civora.Repo.Migrations.CreateQualityControls do
  use Ecto.Migration

  def up do
    create unique_index(:executed_progress_entries, [:id, :work_item_id, :project_id],
             name: :executed_progress_entries_id_work_item_project_id_index
           )

    create table(:quality_controls) do
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :work_item_id, references(:work_items, on_delete: :restrict), null: false

      add :executed_progress_entry_id,
          references(:executed_progress_entries, on_delete: :restrict), null: false

      add :status, :string, null: false
      add :accepted_quantity, :decimal, precision: 18, scale: 4, null: false
      add :rejected_quantity, :decimal, precision: 18, scale: 4, null: false
      add :rejection_reason, :text
      add :non_conformity_originated, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:quality_controls, [:project_id])
    create index(:quality_controls, [:work_item_id])
    create unique_index(:quality_controls, [:executed_progress_entry_id])

    execute """
            ALTER TABLE quality_controls
            ADD CONSTRAINT quality_controls_work_item_belongs_to_project
            FOREIGN KEY (work_item_id, project_id)
            REFERENCES work_items(id, project_id)
            """,
            "ALTER TABLE quality_controls DROP CONSTRAINT quality_controls_work_item_belongs_to_project"

    execute """
            ALTER TABLE quality_controls
            ADD CONSTRAINT quality_controls_progress_belongs_to_work_item
            FOREIGN KEY (executed_progress_entry_id, work_item_id, project_id)
            REFERENCES executed_progress_entries(id, work_item_id, project_id)
            """,
            "ALTER TABLE quality_controls DROP CONSTRAINT quality_controls_progress_belongs_to_work_item"

    create constraint(:quality_controls, :quality_controls_status_check,
             check: "status IN ('accepted', 'partially_accepted', 'rejected')"
           )

    create constraint(:quality_controls, :quality_controls_accepted_quantity_not_negative,
             check: "accepted_quantity >= 0"
           )

    create constraint(:quality_controls, :quality_controls_rejected_quantity_not_negative,
             check: "rejected_quantity >= 0"
           )

    create constraint(:quality_controls, :quality_controls_rejection_reason_length,
             check: "rejection_reason IS NULL OR char_length(rejection_reason) <= 1000"
           )

    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check",
            """
            ALTER TABLE audit_events
            ADD CONSTRAINT audit_events_action_check
            CHECK (action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'executed_progress_created', 'budget_approved', 'quality_accepted', 'estimate_created'))
            """

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'executed_progress_created', 'budget_approved', 'quality_accepted', 'quality_rejected', 'estimate_created')"
           )
  end

  def down do
    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check"

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'executed_progress_created', 'budget_approved', 'quality_accepted', 'estimate_created')"
           )

    drop table(:quality_controls)

    drop index(:executed_progress_entries, [:id, :work_item_id, :project_id],
           name: :executed_progress_entries_id_work_item_project_id_index
         )
  end
end
