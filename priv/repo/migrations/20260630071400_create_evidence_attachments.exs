defmodule Civora.Repo.Migrations.CreateEvidenceAttachments do
  use Ecto.Migration

  def up do
    create unique_index(:non_conformities, [:id, :work_item_id, :project_id],
             name: :non_conformities_id_work_item_project_id_index
           )

    create table(:evidence_attachments) do
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :work_item_id, references(:work_items, on_delete: :restrict), null: false

      add :executed_progress_entry_id,
          references(:executed_progress_entries, on_delete: :restrict)

      add :quality_control_id, references(:quality_controls, on_delete: :restrict)
      add :non_conformity_id, references(:non_conformities, on_delete: :restrict)

      add :object_key, :string, null: false
      add :original_filename, :string, null: false
      add :content_type, :string, null: false
      add :byte_size, :integer, null: false
      add :status, :string, null: false, default: "valid"
      add :uploaded_by_id, references(:users, on_delete: :restrict), null: false
      add :invalidated_by_id, references(:users, on_delete: :restrict)
      add :invalidated_at, :utc_datetime
      add :invalidation_reason, :text

      timestamps(type: :utc_datetime)
    end

    create index(:evidence_attachments, [:project_id])
    create index(:evidence_attachments, [:work_item_id])
    create index(:evidence_attachments, [:executed_progress_entry_id])
    create index(:evidence_attachments, [:quality_control_id])
    create index(:evidence_attachments, [:non_conformity_id])
    create index(:evidence_attachments, [:uploaded_by_id])
    create unique_index(:evidence_attachments, [:object_key])

    execute """
            ALTER TABLE evidence_attachments
            ADD CONSTRAINT evidence_attachments_work_item_belongs_to_project
            FOREIGN KEY (work_item_id, project_id)
            REFERENCES work_items(id, project_id)
            """,
            "ALTER TABLE evidence_attachments DROP CONSTRAINT evidence_attachments_work_item_belongs_to_project"

    execute """
            ALTER TABLE evidence_attachments
            ADD CONSTRAINT evidence_attachments_progress_belongs_to_work_item
            FOREIGN KEY (executed_progress_entry_id, work_item_id, project_id)
            REFERENCES executed_progress_entries(id, work_item_id, project_id)
            """,
            "ALTER TABLE evidence_attachments DROP CONSTRAINT evidence_attachments_progress_belongs_to_work_item"

    execute """
            ALTER TABLE evidence_attachments
            ADD CONSTRAINT evidence_attachments_quality_belongs_to_work_item
            FOREIGN KEY (quality_control_id, work_item_id, project_id)
            REFERENCES quality_controls(id, work_item_id, project_id)
            """,
            "ALTER TABLE evidence_attachments DROP CONSTRAINT evidence_attachments_quality_belongs_to_work_item"

    execute """
            ALTER TABLE evidence_attachments
            ADD CONSTRAINT evidence_attachments_non_conformity_belongs_to_work_item
            FOREIGN KEY (non_conformity_id, work_item_id, project_id)
            REFERENCES non_conformities(id, work_item_id, project_id)
            """,
            "ALTER TABLE evidence_attachments DROP CONSTRAINT evidence_attachments_non_conformity_belongs_to_work_item"

    create constraint(:evidence_attachments, :evidence_attachments_one_parent_check,
             check:
               "num_nonnulls(executed_progress_entry_id, quality_control_id, non_conformity_id) = 1"
           )

    create constraint(:evidence_attachments, :evidence_attachments_status_check,
             check: "status IN ('valid', 'invalidated')"
           )

    create constraint(:evidence_attachments, :evidence_attachments_byte_size_positive,
             check: "byte_size > 0"
           )

    create constraint(:evidence_attachments, :evidence_attachments_filename_length,
             check: "char_length(original_filename) BETWEEN 1 AND 255"
           )

    create constraint(:evidence_attachments, :evidence_attachments_content_type_length,
             check: "char_length(content_type) BETWEEN 1 AND 255"
           )

    create constraint(:evidence_attachments, :evidence_attachments_invalidation_state_check,
             check:
               "(status = 'valid' AND invalidated_by_id IS NULL AND invalidated_at IS NULL AND invalidation_reason IS NULL) OR " <>
                 "(status = 'invalidated' AND invalidated_by_id IS NOT NULL AND invalidated_at IS NOT NULL AND invalidation_reason IS NOT NULL)"
           )

    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check",
            """
            ALTER TABLE audit_events
            ADD CONSTRAINT audit_events_action_check
            CHECK (action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'executed_progress_created', 'budget_approved', 'quality_accepted', 'quality_rejected', 'non_conformity_created', 'non_conformity_closed', 'estimate_created'))
            """

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'executed_progress_created', 'budget_approved', 'quality_accepted', 'quality_rejected', 'non_conformity_created', 'non_conformity_closed', 'estimate_created', 'evidence_uploaded', 'evidence_invalidated')"
           )
  end

  def down do
    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check"

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'work_activity_created', 'executed_progress_created', 'budget_approved', 'quality_accepted', 'quality_rejected', 'non_conformity_created', 'non_conformity_closed', 'estimate_created')"
           )

    drop table(:evidence_attachments)

    drop index(:non_conformities, [:id, :work_item_id, :project_id],
           name: :non_conformities_id_work_item_project_id_index
         )
  end
end
