defmodule Civora.Repo.Migrations.CreateNonConformities do
  use Ecto.Migration

  def up do
    create unique_index(:quality_controls, [:id, :work_item_id, :project_id],
             name: :quality_controls_id_work_item_project_id_index
           )

    create table(:non_conformities) do
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :work_item_id, references(:work_items, on_delete: :restrict), null: false
      add :quality_control_id, references(:quality_controls, on_delete: :restrict)

      add :executed_progress_entry_id,
          references(:executed_progress_entries, on_delete: :restrict)

      add :defect, :text, null: false
      add :location_sector, :string, null: false
      add :responsible_name, :string, null: false
      add :status, :string, null: false, default: "open"
      add :affected_quantity, :decimal, precision: 18, scale: 4, null: false
      add :disposition, :text
      add :due_on, :date
      add :closure_notes, :text
      add :closed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:non_conformities, [:project_id])
    create index(:non_conformities, [:work_item_id])

    create unique_index(:non_conformities, [:quality_control_id],
             where: "quality_control_id IS NOT NULL"
           )

    execute """
            ALTER TABLE non_conformities
            ADD CONSTRAINT non_conformities_work_item_belongs_to_project
            FOREIGN KEY (work_item_id, project_id)
            REFERENCES work_items(id, project_id)
            """,
            "ALTER TABLE non_conformities DROP CONSTRAINT non_conformities_work_item_belongs_to_project"

    execute """
            ALTER TABLE non_conformities
            ADD CONSTRAINT non_conformities_quality_control_belongs_to_work_item
            FOREIGN KEY (quality_control_id, work_item_id, project_id)
            REFERENCES quality_controls(id, work_item_id, project_id)
            """,
            "ALTER TABLE non_conformities DROP CONSTRAINT non_conformities_quality_control_belongs_to_work_item"

    execute """
            ALTER TABLE non_conformities
            ADD CONSTRAINT non_conformities_progress_belongs_to_work_item
            FOREIGN KEY (executed_progress_entry_id, work_item_id, project_id)
            REFERENCES executed_progress_entries(id, work_item_id, project_id)
            """,
            "ALTER TABLE non_conformities DROP CONSTRAINT non_conformities_progress_belongs_to_work_item"

    create constraint(:non_conformities, :non_conformities_status_check,
             check: "status IN ('open', 'closed')"
           )

    create constraint(:non_conformities, :non_conformities_affected_quantity_positive,
             check: "affected_quantity > 0"
           )

    create constraint(:non_conformities, :non_conformities_defect_length,
             check: "char_length(defect) BETWEEN 2 AND 2000"
           )

    create constraint(:non_conformities, :non_conformities_location_sector_length,
             check: "char_length(location_sector) BETWEEN 2 AND 160"
           )

    create constraint(:non_conformities, :non_conformities_responsible_name_length,
             check: "char_length(responsible_name) BETWEEN 2 AND 160"
           )

    create constraint(:non_conformities, :non_conformities_disposition_length,
             check: "disposition IS NULL OR char_length(disposition) <= 1000"
           )

    create constraint(:non_conformities, :non_conformities_closure_notes_length,
             check: "closure_notes IS NULL OR char_length(closure_notes) <= 1000"
           )

    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check",
            """
            ALTER TABLE audit_events
            ADD CONSTRAINT audit_events_action_check
            CHECK (action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'executed_progress_created', 'budget_approved', 'quality_accepted', 'quality_rejected', 'estimate_created'))
            """

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'executed_progress_created', 'budget_approved', 'quality_accepted', 'quality_rejected', 'non_conformity_created', 'non_conformity_closed', 'estimate_created')"
           )
  end

  def down do
    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check"

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'executed_progress_created', 'budget_approved', 'quality_accepted', 'quality_rejected', 'estimate_created')"
           )

    drop table(:non_conformities)

    drop index(:quality_controls, [:id, :work_item_id, :project_id],
           name: :quality_controls_id_work_item_project_id_index
         )
  end
end
