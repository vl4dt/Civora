defmodule Civora.Repo.Migrations.CreateSubcontractEstimates do
  use Ecto.Migration

  def up do
    create_if_not_exists unique_index(:quality_controls, [:id, :work_item_id, :project_id],
                           name: :quality_controls_id_work_item_project_id_index
                         )

    create table(:subcontract_estimates) do
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :subcontract_id, references(:subcontracts, on_delete: :restrict), null: false
      add :status, :string, null: false
      add :amount, :decimal, precision: 18, scale: 4, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:subcontract_estimates, [:project_id])
    create index(:subcontract_estimates, [:subcontract_id])

    create unique_index(:subcontract_estimates, [:id, :project_id],
             name: :subcontract_estimates_id_project_id_index
           )

    execute """
            ALTER TABLE subcontract_estimates
            ADD CONSTRAINT subcontract_estimates_subcontract_belongs_to_project
            FOREIGN KEY (subcontract_id, project_id)
            REFERENCES subcontracts(id, project_id)
            ON DELETE RESTRICT
            """,
            """
            ALTER TABLE subcontract_estimates
            DROP CONSTRAINT subcontract_estimates_subcontract_belongs_to_project
            """

    create constraint(:subcontract_estimates, :subcontract_estimates_status_check,
             check: "status IN ('generated')"
           )

    create constraint(:subcontract_estimates, :subcontract_estimates_amount_not_negative,
             check: "amount >= 0"
           )

    create table(:subcontract_estimate_lines) do
      add :project_id, references(:projects, on_delete: :restrict), null: false

      add :subcontract_estimate_id, references(:subcontract_estimates, on_delete: :restrict),
        null: false

      add :subcontract_id, references(:subcontracts, on_delete: :restrict), null: false
      add :work_item_id, references(:work_items, on_delete: :restrict), null: false
      add :quality_control_id, references(:quality_controls, on_delete: :restrict), null: false

      add :executed_progress_entry_id,
          references(:executed_progress_entries, on_delete: :restrict), null: false

      add :quantity, :decimal, precision: 18, scale: 4, null: false
      add :unit_price, :decimal, precision: 18, scale: 4, null: false
      add :amount, :decimal, precision: 18, scale: 4, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:subcontract_estimate_lines, [:project_id])
    create index(:subcontract_estimate_lines, [:subcontract_estimate_id])
    create index(:subcontract_estimate_lines, [:subcontract_id])
    create index(:subcontract_estimate_lines, [:work_item_id])
    create unique_index(:subcontract_estimate_lines, [:quality_control_id])

    execute """
            ALTER TABLE subcontract_estimate_lines
            ADD CONSTRAINT subcontract_estimate_lines_estimate_belongs_to_project
            FOREIGN KEY (subcontract_estimate_id, project_id)
            REFERENCES subcontract_estimates(id, project_id)
            ON DELETE RESTRICT
            """,
            """
            ALTER TABLE subcontract_estimate_lines
            DROP CONSTRAINT subcontract_estimate_lines_estimate_belongs_to_project
            """

    execute """
            ALTER TABLE subcontract_estimate_lines
            ADD CONSTRAINT subcontract_estimate_lines_subcontract_belongs_to_project
            FOREIGN KEY (subcontract_id, project_id)
            REFERENCES subcontracts(id, project_id)
            ON DELETE RESTRICT
            """,
            """
            ALTER TABLE subcontract_estimate_lines
            DROP CONSTRAINT subcontract_estimate_lines_subcontract_belongs_to_project
            """

    execute """
            ALTER TABLE subcontract_estimate_lines
            ADD CONSTRAINT subcontract_estimate_lines_work_item_belongs_to_subcontract
            FOREIGN KEY (subcontract_id, work_item_id)
            REFERENCES subcontract_work_items(subcontract_id, work_item_id)
            ON DELETE RESTRICT
            """,
            """
            ALTER TABLE subcontract_estimate_lines
            DROP CONSTRAINT subcontract_estimate_lines_work_item_belongs_to_subcontract
            """

    execute """
            ALTER TABLE subcontract_estimate_lines
            ADD CONSTRAINT subcontract_estimate_lines_quality_belongs_to_work_item
            FOREIGN KEY (quality_control_id, work_item_id, project_id)
            REFERENCES quality_controls(id, work_item_id, project_id)
            ON DELETE RESTRICT
            """,
            """
            ALTER TABLE subcontract_estimate_lines
            DROP CONSTRAINT subcontract_estimate_lines_quality_belongs_to_work_item
            """

    create constraint(:subcontract_estimate_lines, :subcontract_estimate_lines_quantity_positive,
             check: "quantity > 0"
           )

    create constraint(
             :subcontract_estimate_lines,
             :subcontract_estimate_lines_unit_price_positive,
             check: "unit_price > 0"
           )

    create constraint(:subcontract_estimate_lines, :subcontract_estimate_lines_amount_positive,
             check: "amount > 0"
           )
  end

  def down do
    drop table(:subcontract_estimate_lines)
    drop table(:subcontract_estimates)

    drop_if_exists index(:quality_controls, [:id, :work_item_id, :project_id],
                     name: :quality_controls_id_work_item_project_id_index
                   )
  end
end
