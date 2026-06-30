defmodule Civora.SubcontractsTest do
  use Civora.DataCase

  import Civora.AccountsFixtures
  import Civora.ExecutionFixtures
  import Civora.ProjectsFixtures
  import Civora.SubcontractsFixtures

  alias Civora.Accounts.Scope
  alias Civora.Audit.AuditEvent
  alias Civora.Projects
  alias Civora.Repo
  alias Civora.Subcontracts

  alias Civora.Subcontracts.{
    Counterparty,
    Subcontract,
    SubcontractEstimate,
    SubcontractEstimateLine
  }

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

    test "creates a subcontract estimate from selected unestimated payable quantities", %{
      scope: scope,
      project: project,
      work_items: [first_item, second_item] = work_items,
      counterparty: counterparty
    } do
      first_item = %{first_item | quantity: Decimal.new("10.0000")}
      second_item = %{second_item | quantity: Decimal.new("10.0000")}

      subcontract =
        subcontract_fixture(scope, project, work_items, counterparty, %{
          current_contract_amount: "200.0000"
        })

      first_activity = work_activity_fixture(scope, project, first_item)
      second_activity = work_activity_fixture(scope, project, second_item)

      first_progress =
        executed_progress_fixture(scope, project, first_activity, %{quantity: "8.0000"})

      second_progress =
        executed_progress_fixture(scope, project, second_activity, %{quantity: "4.0000"})

      first_control =
        quality_control_fixture(scope, project, first_progress, %{
          accepted_quantity: "5.0000",
          rejection_reason: "Remate incompleto"
        })

      second_control =
        quality_control_fixture(scope, project, second_progress, %{accepted_quantity: "4.0000"})

      assert {:ok, estimable} =
               Subcontracts.list_estimable_payable_progress(scope, project, subcontract)

      assert Enum.map(estimable, & &1.quality_control.id) == [first_control.id, second_control.id]

      assert {:ok, %SubcontractEstimate{} = estimate} =
               Subcontracts.create_subcontract_estimate(scope, project, subcontract, %{
                 quality_control_ids: [first_control.id]
               })

      assert estimate.status == :generated
      assert Decimal.equal?(estimate.amount, Decimal.new("19.6080"))
      assert [%SubcontractEstimateLine{} = line] = estimate.lines
      assert line.quality_control_id == first_control.id
      assert Decimal.equal?(line.quantity, Decimal.new("5.0000"))
      assert Decimal.equal?(line.unit_price, Decimal.new("3.9216"))
      assert Decimal.equal?(line.amount, Decimal.new("19.6080"))

      assert {:ok, [remaining]} =
               Subcontracts.list_estimable_payable_progress(scope, project, subcontract)

      assert remaining.quality_control.id == second_control.id

      assert {:error, :invalid_quality_control_ids} =
               Subcontracts.create_subcontract_estimate(scope, project, subcontract, %{
                 quality_control_ids: [first_control.id]
               })

      event = Repo.get_by!(AuditEvent, action: :estimate_created, entity_id: estimate.id)
      assert event.entity_type == "subcontract_estimate"
      assert event.new_state["status"] == "generated"

      assert event.new_state["lines"] |> hd() |> Map.fetch!("quality_control_id") ==
               first_control.id
    end

    test "rejects estimate creation without payable selections or estimate permission", %{
      scope: scope,
      project: project,
      work_items: [work_item | _] = work_items,
      counterparty: counterparty
    } do
      subcontract = subcontract_fixture(scope, project, work_items, counterparty)
      activity = work_activity_fixture(scope, project, work_item)
      progress = executed_progress_fixture(scope, project, activity)
      control = quality_control_fixture(scope, project, progress)

      assert {:error, :no_estimable_progress} =
               Subcontracts.create_subcontract_estimate(scope, project, subcontract, %{
                 quality_control_ids: []
               })

      viewer = user_fixture()
      assignment_fixture(scope, project, viewer, :consulta)

      assert {:error, :unauthorized} =
               Subcontracts.create_subcontract_estimate(
                 Scope.for_user(viewer),
                 project,
                 subcontract,
                 %{
                   quality_control_ids: [control.id]
                 }
               )
    end

    test "rejects estimates that exceed the current contract amount", %{
      scope: scope,
      project: project,
      work_items: [work_item | _] = work_items,
      counterparty: counterparty
    } do
      subcontract =
        subcontract_fixture(scope, project, work_items, counterparty, %{
          current_contract_amount: "100.0000"
        })

      activity = work_activity_fixture(scope, project, work_item)
      progress = executed_progress_fixture(scope, project, activity, %{quantity: "60.0000"})
      control = quality_control_fixture(scope, project, progress, %{accepted_quantity: "60.0000"})

      assert {:error, {:estimate_exceeds_contract_balance, balance}} =
               Subcontracts.create_subcontract_estimate(scope, project, subcontract, %{
                 quality_control_ids: [control.id]
               })

      assert Decimal.equal?(balance.current_contract_amount, Decimal.new("100.0000"))
      assert Decimal.equal?(balance.estimated_amount, Decimal.new("0.0000"))
      assert Decimal.equal?(balance.available_balance, Decimal.new("100.0000"))
      assert Decimal.gt?(balance.estimate_amount, balance.available_balance)
      assert Repo.aggregate(SubcontractEstimate, :count) == 0

      assert Repo.aggregate(
               from(e in AuditEvent, where: e.action == :estimate_created),
               :count
             ) == 0
    end

    test "rejects an estimate that would exceed remaining contract balance", %{
      scope: scope,
      project: project,
      work_items: [work_item | _] = work_items,
      counterparty: counterparty
    } do
      subcontract =
        subcontract_fixture(scope, project, work_items, counterparty, %{
          current_contract_amount: "100.0000"
        })

      first_activity =
        work_activity_fixture(scope, project, work_item, %{location_sector: "Nivel 1"})

      second_activity =
        work_activity_fixture(scope, project, work_item, %{location_sector: "Nivel 2"})

      first_progress =
        executed_progress_fixture(scope, project, first_activity, %{quantity: "30.0000"})

      second_progress =
        executed_progress_fixture(scope, project, second_activity, %{quantity: "30.0000"})

      first_control =
        quality_control_fixture(scope, project, first_progress, %{accepted_quantity: "30.0000"})

      second_control =
        quality_control_fixture(scope, project, second_progress, %{accepted_quantity: "30.0000"})

      assert {:ok, first_estimate} =
               Subcontracts.create_subcontract_estimate(scope, project, subcontract, %{
                 quality_control_ids: [first_control.id]
               })

      assert Decimal.equal?(first_estimate.amount, Decimal.new("58.8240"))

      assert {:error, {:estimate_exceeds_contract_balance, balance}} =
               Subcontracts.create_subcontract_estimate(scope, project, subcontract, %{
                 quality_control_ids: [second_control.id]
               })

      assert Decimal.equal?(balance.estimated_amount, Decimal.new("58.8240"))
      assert Decimal.equal?(balance.available_balance, Decimal.new("41.1760"))
      assert Decimal.equal?(balance.estimate_amount, Decimal.new("58.8240"))
      assert Repo.aggregate(SubcontractEstimate, :count) == 1
    end
  end
end
