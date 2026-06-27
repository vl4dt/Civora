defmodule Civora.SubcontractsTest do
  use Civora.DataCase

  import Civora.AccountsFixtures
  import Civora.ProjectsFixtures
  import Civora.SubcontractsFixtures

  alias Civora.Accounts.Scope
  alias Civora.Audit.AuditEvent
  alias Civora.Projects
  alias Civora.Repo
  alias Civora.Subcontracts
  alias Civora.Subcontracts.{Counterparty, Subcontract}

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

  describe "project subcontracts" do
    setup %{scope: scope} do
      project = project_fixture(scope)
      phase = project_phase_fixture(scope, project)
      first_item = work_item_fixture(scope, project, phase, %{description: "Mamposteria"})
      second_item = work_item_fixture(scope, project, phase, %{description: "Repello"})
      counterparty = counterparty_fixture(scope, %{name: "Constructora Rivera"})

      %{
        project: project,
        work_items: [first_item, second_item],
        counterparty: counterparty
      }
    end

    test "creates one agreement for multiple project work items and audits it atomically", %{
      scope: scope,
      project: project,
      work_items: work_items,
      counterparty: counterparty
    } do
      assert {:ok, %Subcontract{} = subcontract} =
               Subcontracts.create_subcontract(scope, project, %{
                 name: "Alcance de obra gris",
                 counterparty_id: counterparty.id,
                 work_item_ids: Enum.map(work_items, & &1.id),
                 supply_modality: :mixta,
                 current_contract_amount: "450000.25",
                 advance_percentage: "15",
                 retention_percentage: "5",
                 amortization_percentage: "15"
               })

      assert subcontract.project_id == project.id
      assert subcontract.counterparty.id == counterparty.id

      assert Enum.map(subcontract.work_items, & &1.id) |> Enum.sort() ==
               Enum.map(work_items, & &1.id) |> Enum.sort()

      assert Decimal.equal?(subcontract.current_contract_amount, Decimal.new("450000.25"))
      assert {:ok, [listed]} = Subcontracts.list_subcontracts(scope, project)
      assert listed.id == subcontract.id
      assert {:ok, fetched} = Subcontracts.get_subcontract(scope, project, subcontract.id)
      assert fetched.name == "Alcance de obra gris"

      event = Repo.get_by!(AuditEvent, action: :subcontract_created, entity_id: subcontract.id)
      assert event.project_id == project.id
      assert event.new_state["counterparty_id"] == counterparty.id
      assert event.new_state["work_item_ids"] == Enum.map(work_items, & &1.id)
    end

    test "rejects provider-only counterparties without partial records", %{
      scope: scope,
      project: project,
      work_items: [work_item | _]
    } do
      provider = counterparty_fixture(scope, %{role: :proveedor})

      assert {:error, changeset} =
               Subcontracts.create_subcontract(scope, project, %{
                 name: "Proveedor incorrecto",
                 counterparty_id: provider.id,
                 work_item_ids: [work_item.id],
                 supply_modality: :solo_mano_obra,
                 current_contract_amount: "1000",
                 advance_percentage: "0",
                 retention_percentage: "0",
                 amortization_percentage: "0"
               })

      assert "must be an eligible subcontractor counterparty" in errors_on(changeset).counterparty_id
      assert Repo.aggregate(Subcontract, :count) == 0

      assert Repo.aggregate(
               from(e in AuditEvent, where: e.action == :subcontract_created),
               :count
             ) == 0
    end

    test "rejects work items from another project", %{
      scope: scope,
      project: project,
      counterparty: counterparty
    } do
      other_project = project_fixture(scope)
      other_phase = project_phase_fixture(scope, other_project)
      foreign_item = work_item_fixture(scope, other_project, other_phase)

      assert {:error, changeset} =
               Subcontracts.create_subcontract(scope, project, %{
                 name: "Alcance cruzado",
                 counterparty_id: counterparty.id,
                 work_item_ids: [foreign_item.id],
                 supply_modality: :solo_mano_obra,
                 current_contract_amount: "1000",
                 advance_percentage: "0",
                 retention_percentage: "0",
                 amortization_percentage: "0"
               })

      assert "must belong to the project" in errors_on(changeset).work_item_ids
      assert Repo.aggregate(Subcontract, :count) == 0
    end

    test "validates financial terms and requires at least one work item", %{
      scope: scope,
      project: project,
      counterparty: counterparty
    } do
      assert {:error, changeset} =
               Subcontracts.create_subcontract(scope, project, %{
                 name: "Condiciones invalidas",
                 counterparty_id: counterparty.id,
                 work_item_ids: [],
                 supply_modality: :mano_obra_materiales,
                 current_contract_amount: "0",
                 advance_percentage: "101",
                 retention_percentage: "-1",
                 amortization_percentage: "20"
               })

      errors = errors_on(changeset)
      assert errors.work_item_ids
      assert errors.current_contract_amount
      assert errors.advance_percentage
      assert errors.retention_percentage
    end

    test "directors can create while read-only members cannot", %{
      scope: administrator_scope,
      project: project,
      work_items: work_items,
      counterparty: counterparty
    } do
      director = user_fixture()
      assignment_fixture(administrator_scope, project, director, :director_proyecto)

      attrs = %{
        name: "Contrato del director",
        counterparty_id: counterparty.id,
        work_item_ids: [hd(work_items).id],
        supply_modality: :solo_mano_obra,
        current_contract_amount: "5000",
        advance_percentage: "0",
        retention_percentage: "5",
        amortization_percentage: "0"
      }

      assert {:ok, _subcontract} =
               Subcontracts.create_subcontract(Scope.for_user(director), project, attrs)

      viewer = user_fixture()
      assignment_fixture(administrator_scope, project, viewer, :consulta)

      assert {:error, :unauthorized} =
               Subcontracts.create_subcontract(Scope.for_user(viewer), project, attrs)
    end

    test "members can inspect and outsiders cannot", %{
      scope: administrator_scope,
      project: project,
      work_items: work_items,
      counterparty: counterparty
    } do
      subcontract = subcontract_fixture(administrator_scope, project, work_items, counterparty)
      viewer = user_fixture()
      assignment_fixture(administrator_scope, project, viewer, :consulta)
      viewer_scope = Scope.for_user(viewer)

      assert {:ok, [listed]} = Subcontracts.list_subcontracts(viewer_scope, project)
      assert listed.id == subcontract.id

      outsider_scope = user_fixture() |> Scope.for_user()
      assert {:error, :unauthorized} = Subcontracts.list_subcontracts(outsider_scope, project)

      assert {:error, :unauthorized} =
               Subcontracts.get_subcontract(outsider_scope, project, subcontract.id)

      refute Projects.authorized?(viewer_scope, project, :manage_subcontracts)
    end
  end
end
