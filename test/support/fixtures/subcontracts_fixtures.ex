defmodule Civora.SubcontractsFixtures do
  @moduledoc """
  Test helpers for counterparties and project subcontracts.
  """

  alias Civora.Subcontracts

  def counterparty_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Counterparty #{System.unique_integer([:positive])}",
        role: :subcontratista,
        contact: "contact@example.com"
      })

    {:ok, counterparty} = Subcontracts.create_counterparty(scope, attrs)
    counterparty
  end

  def subcontract_fixture(scope, project, work_items, counterparty \\ nil, attrs \\ %{}) do
    counterparty = counterparty || counterparty_fixture(scope)

    attrs =
      Enum.into(attrs, %{
        name: "Subcontract #{System.unique_integer([:positive])}",
        counterparty_id: counterparty.id,
        work_item_ids: Enum.map(work_items, & &1.id),
        supply_modality: :solo_mano_obra,
        current_contract_amount: "125000.0000",
        advance_percentage: "20.0000",
        retention_percentage: "5.0000",
        amortization_percentage: "20.0000"
      })

    {:ok, subcontract} = Subcontracts.create_subcontract(scope, project, attrs)
    subcontract
  end
end
