defmodule Civora.Subcontracts.Counterparty do
  use Ecto.Schema
  import Ecto.Changeset

  @roles [:proveedor, :subcontratista, :ambos]

  schema "counterparties" do
    field :name, :string
    field :role, Ecto.Enum, values: @roles
    field :contact, :string

    has_many :subcontracts, Civora.Subcontracts.Subcontract

    timestamps(type: :utc_datetime)
  end

  def roles, do: @roles

  def changeset(counterparty, attrs) do
    counterparty
    |> cast(attrs, [:name, :role, :contact])
    |> update_change(:name, &String.trim/1)
    |> update_change(:contact, &normalize_optional/1)
    |> validate_required([:name, :role])
    |> validate_length(:name, min: 2, max: 160)
    |> validate_length(:contact, max: 500)
    |> check_constraint(:role, name: :counterparties_role_check)
  end

  defp normalize_optional(nil), do: nil

  defp normalize_optional(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end
end
