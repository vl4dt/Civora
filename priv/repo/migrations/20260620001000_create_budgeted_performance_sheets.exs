defmodule Civora.Repo.Migrations.CreateBudgetedPerformanceSheets do
  use Ecto.Migration

  @resource_categories ~w(material labor)

  def change do
    create unique_index(:work_items, [:id, :project_id], name: :work_items_id_project_id_index)

    create table(:budgeted_performance_sheets) do
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :work_item_id, references(:work_items, on_delete: :restrict), null: false

      add :source_performance_sheet_id,
          references(:performance_sheets, on_delete: :restrict),
          null: false

      add :name, :string, null: false
      add :description, :text, null: false
      add :unit, :string, null: false
      add :productivity, :decimal, precision: 18, scale: 4
      add :waste_percentage, :decimal, precision: 7, scale: 4

      timestamps(type: :utc_datetime)
    end

    create unique_index(:budgeted_performance_sheets, [:work_item_id])
    create index(:budgeted_performance_sheets, [:project_id])
    create index(:budgeted_performance_sheets, [:source_performance_sheet_id])

    create constraint(
             :budgeted_performance_sheets,
             :budgeted_performance_sheets_productivity_positive,
             check: "productivity IS NULL OR productivity > 0"
           )

    create constraint(
             :budgeted_performance_sheets,
             :budgeted_performance_sheets_waste_percentage_range,
             check:
               "waste_percentage IS NULL OR (waste_percentage >= 0 AND waste_percentage <= 100)"
           )

    execute """
            ALTER TABLE budgeted_performance_sheets
            ADD CONSTRAINT budgeted_performance_sheets_work_item_belongs_to_project
            FOREIGN KEY (work_item_id, project_id)
            REFERENCES work_items(id, project_id)
            ON DELETE RESTRICT
            """,
            "ALTER TABLE budgeted_performance_sheets DROP CONSTRAINT budgeted_performance_sheets_work_item_belongs_to_project"

    create table(:budgeted_performance_sheet_resources) do
      add :budgeted_performance_sheet_id,
          references(:budgeted_performance_sheets,
            on_delete: :delete_all,
            name: :budgeted_sheet_resources_sheet_id_fkey
          ),
          null: false

      add :category, :string, null: false
      add :name, :string, null: false
      add :unit, :string, null: false
      add :quantity, :decimal, precision: 18, scale: 4, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:budgeted_performance_sheet_resources, [:budgeted_performance_sheet_id],
             name: :budgeted_sheet_resources_sheet_id_index
           )

    create constraint(
             :budgeted_performance_sheet_resources,
             :budgeted_performance_sheet_resources_category_check,
             check: "category IN (#{quoted_values(@resource_categories)})"
           )

    create constraint(
             :budgeted_performance_sheet_resources,
             :budgeted_performance_sheet_resources_quantity_positive,
             check: "quantity > 0"
           )
  end

  defp quoted_values(values), do: Enum.map_join(values, ", ", &"'#{&1}'")
end
