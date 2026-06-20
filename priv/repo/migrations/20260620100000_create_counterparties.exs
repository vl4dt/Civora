defmodule Civora.Repo.Migrations.CreateCounterparties do
  use Ecto.Migration

  def change do
    create table(:counterparties) do
      add :name, :string, null: false
      add :role, :string, null: false
      add :contact, :text

      timestamps(type: :utc_datetime)
    end

    create index(:counterparties, [:name])

    create constraint(:counterparties, :counterparties_role_check,
             check: "role IN ('proveedor', 'subcontratista', 'ambos')"
           )
  end
end
