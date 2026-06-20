defmodule Civora.SubcontractsTest do
  use Civora.DataCase

  import Civora.AccountsFixtures

  alias Civora.Accounts.Scope
  alias Civora.Subcontracts
  alias Civora.Subcontracts.Counterparty

  setup do
    %{scope: user_fixture() |> Scope.for_user()}
  end

  test "creates, lists, and gets a counterparty", %{scope: scope} do
    assert {:ok, %Counterparty{} = counterparty} =
             Subcontracts.create_counterparty(scope, %{
               name: "  Constructora Rivera  ",
               role: :subcontratista,
               contact: " Ana Rivera, ana@example.com "
             })

    assert counterparty.name == "Constructora Rivera"
    assert counterparty.contact == "Ana Rivera, ana@example.com"
    assert Subcontracts.list_counterparties(scope) == [counterparty]
    assert Subcontracts.get_counterparty(scope, counterparty.id) == {:ok, counterparty}
  end

  test "supports both canonical roles and an optional contact", %{scope: scope} do
    assert Subcontracts.available_counterparty_roles() == [:proveedor, :subcontratista, :ambos]

    assert {:ok, counterparty} =
             Subcontracts.create_counterparty(scope, %{
               name: "Grupo Mixto",
               role: :ambos,
               contact: " "
             })

    assert counterparty.contact == nil

    assert {:ok, counterparty_with_null_contact} =
             Subcontracts.create_counterparty(scope, %{
               name: "Proveedor sin contacto",
               role: :proveedor,
               contact: nil
             })

    assert counterparty_with_null_contact.contact == nil
  end

  test "requires a valid name and role", %{scope: scope} do
    assert {:error, changeset} =
             Subcontracts.create_counterparty(scope, %{name: " ", role: :cliente})

    assert %{name: [_], role: [_]} = errors_on(changeset)
  end

  test "returns not found for an unknown identity", %{scope: scope} do
    assert Subcontracts.get_counterparty(scope, -1) == {:error, :not_found}
  end
end
