defmodule Civora.Subcontracts.Subcontract do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.WorkItem
  alias Civora.Projects.Project
  alias Civora.Subcontracts.Counterparty

  @supply_modalities [:solo_mano_obra, :mano_obra_materiales, :mixta]

  schema "subcontracts" do
    field :name, :string
    field :supply_modality, Ecto.Enum, values: @supply_modalities
    field :current_contract_amount, :decimal
    field :advance_percentage, :decimal, default: Decimal.new("0")
    field :retention_percentage, :decimal, default: Decimal.new("0")
    field :amortization_percentage, :decimal, default: Decimal.new("0")
    field :work_item_ids, {:array, :integer}, virtual: true, default: []

    belongs_to :project, Project
    belongs_to :counterparty, Counterparty

    many_to_many :work_items, WorkItem,
      join_through: "subcontract_work_items",
      on_replace: :delete

    has_many :estimates, Civora.Subcontracts.SubcontractEstimate

    timestamps(type: :utc_datetime)
  end

  def supply_modalities, do: @supply_modalities

  def changeset(subcontract, attrs) do
    subcontract
    |> cast(attrs, [
      :name,
      :project_id,
      :counterparty_id,
      :supply_modality,
      :current_contract_amount,
      :advance_percentage,
      :retention_percentage,
      :amortization_percentage,
      :work_item_ids
    ])
    |> update_change(:name, &String.trim/1)
    |> update_change(:work_item_ids, &Enum.uniq/1)
    |> validate_required([
      :name,
      :project_id,
      :counterparty_id,
      :supply_modality,
      :current_contract_amount,
      :work_item_ids
    ])
    |> validate_length(:name, min: 2, max: 160)
    |> validate_work_item_ids()
    |> validate_number(:current_contract_amount, greater_than: 0)
    |> validate_percentage(:advance_percentage)
    |> validate_percentage(:retention_percentage)
    |> validate_percentage(:amortization_percentage)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:counterparty_id)
    |> check_constraint(:supply_modality, name: :subcontracts_supply_modality_check)
    |> check_constraint(:current_contract_amount,
      name: :subcontracts_current_contract_amount_positive
    )
    |> check_constraint(:advance_percentage, name: :subcontracts_advance_percentage_range)
    |> check_constraint(:retention_percentage, name: :subcontracts_retention_percentage_range)
    |> check_constraint(:amortization_percentage,
      name: :subcontracts_amortization_percentage_range
    )
  end

  defp validate_percentage(changeset, field) do
    validate_number(changeset, field,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    )
  end

  defp validate_work_item_ids(changeset) do
    case get_field(changeset, :work_item_ids) do
      [] -> add_error(changeset, :work_item_ids, "must include at least one work item")
      _ids -> changeset
    end
  end
end
