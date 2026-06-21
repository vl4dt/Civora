defmodule Civora.Repo.Migrations.CreateSubcontracts do
  use Ecto.Migration

  def up do
    create table(:subcontracts) do
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :counterparty_id, references(:counterparties, on_delete: :restrict), null: false
      add :name, :string, null: false
      add :supply_modality, :string, null: false
      add :current_contract_amount, :decimal, precision: 18, scale: 4, null: false
      add :advance_percentage, :decimal, precision: 7, scale: 4, null: false, default: 0
      add :retention_percentage, :decimal, precision: 7, scale: 4, null: false, default: 0
      add :amortization_percentage, :decimal, precision: 7, scale: 4, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:subcontracts, [:project_id])
    create index(:subcontracts, [:counterparty_id])

    create unique_index(:subcontracts, [:id, :project_id],
             name: :subcontracts_id_project_id_index
           )

    create constraint(:subcontracts, :subcontracts_supply_modality_check,
             check: "supply_modality IN ('solo_mano_obra', 'mano_obra_materiales', 'mixta')"
           )

    create constraint(:subcontracts, :subcontracts_current_contract_amount_positive,
             check: "current_contract_amount > 0"
           )

    for field <- ~w(advance_percentage retention_percentage amortization_percentage) do
      create constraint(:subcontracts, "subcontracts_#{field}_range",
               check: "#{field} >= 0 AND #{field} <= 100"
             )
    end

    create table(:subcontract_work_items, primary_key: false) do
      add :project_id, references(:projects, on_delete: :restrict), null: false, primary_key: true

      add :subcontract_id, references(:subcontracts, on_delete: :restrict),
        null: false,
        primary_key: true

      add :work_item_id, references(:work_items, on_delete: :restrict),
        null: false,
        primary_key: true

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:subcontract_work_items, [:subcontract_id, :work_item_id],
             name: :subcontract_work_items_subcontract_work_item_index
           )

    execute """
            ALTER TABLE subcontract_work_items
            ADD CONSTRAINT subcontract_work_items_subcontract_belongs_to_project
            FOREIGN KEY (subcontract_id, project_id)
            REFERENCES subcontracts(id, project_id)
            ON DELETE RESTRICT
            """,
            """
            ALTER TABLE subcontract_work_items
            DROP CONSTRAINT subcontract_work_items_subcontract_belongs_to_project
            """

    execute """
            ALTER TABLE subcontract_work_items
            ADD CONSTRAINT subcontract_work_items_work_item_belongs_to_project
            FOREIGN KEY (work_item_id, project_id)
            REFERENCES work_items(id, project_id)
            ON DELETE RESTRICT
            """,
            """
            ALTER TABLE subcontract_work_items
            DROP CONSTRAINT subcontract_work_items_work_item_belongs_to_project
            """

    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check"

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'subcontract_created', 'budget_approved', 'quality_accepted', 'estimate_created')"
           )
  end

  def down do
    execute "ALTER TABLE audit_events DROP CONSTRAINT audit_events_action_check"

    create constraint(:audit_events, :audit_events_action_check,
             check:
               "action IN ('project_created', 'project_phase_created', 'project_assignment_created', 'project_assignment_role_changed', 'project_assignment_removed', 'work_item_created', 'budget_approved', 'quality_accepted', 'estimate_created')"
           )

    drop table(:subcontract_work_items)
    drop table(:subcontracts)
  end
end
