defmodule Civora.Repo.Migrations.CreatePerformanceSheets do
  use Ecto.Migration

  @resource_categories ~w(material labor)

  def change do
    create table(:performance_sheets) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :unit, :string, null: false
      add :productivity, :decimal, precision: 18, scale: 4
      add :waste_percentage, :decimal, precision: 7, scale: 4

      timestamps(type: :utc_datetime)
    end

    create unique_index(:performance_sheets, [:name])

    create constraint(:performance_sheets, :performance_sheets_productivity_positive,
             check: "productivity IS NULL OR productivity > 0"
           )

    create constraint(:performance_sheets, :performance_sheets_waste_percentage_range,
             check:
               "waste_percentage IS NULL OR (waste_percentage >= 0 AND waste_percentage <= 100)"
           )

    create table(:performance_sheet_resources) do
      add :performance_sheet_id, references(:performance_sheets, on_delete: :delete_all),
        null: false

      add :category, :string, null: false
      add :name, :string, null: false
      add :unit, :string, null: false
      add :quantity, :decimal, precision: 18, scale: 4, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:performance_sheet_resources, [:performance_sheet_id])

    create constraint(:performance_sheet_resources, :performance_sheet_resources_category_check,
             check: "category IN (#{quoted_values(@resource_categories)})"
           )

    create constraint(
             :performance_sheet_resources,
             :performance_sheet_resources_quantity_positive,
             check: "quantity > 0"
           )
  end

  defp quoted_values(values), do: Enum.map_join(values, ", ", &"'#{&1}'")
end
