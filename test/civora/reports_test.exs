defmodule Civora.ReportsTest do
  use Civora.DataCase

  import Civora.AccountsFixtures
  import Civora.ExecutionFixtures
  import Civora.ProjectsFixtures
  import Civora.SubcontractsFixtures

  alias Civora.Accounts.Scope
  alias Civora.Reports

  setup do
    scope = user_fixture() |> Scope.for_user()
    project = project_fixture(scope, %{name: "Proyecto Reporte"})
    phase = project_phase_fixture(scope, project, %{name: "Construccion"})
    first_item = work_item_fixture(scope, project, phase, %{description: "Mamposteria"})
    second_item = work_item_fixture(scope, project, phase, %{description: "Repello"})
    counterparty = counterparty_fixture(scope, %{name: "Obras Rivera"})

    %{
      scope: scope,
      project: project,
      work_items: [first_item, second_item],
      counterparty: counterparty
    }
  end

  test "builds the internal project report from budget, progress, quality, estimates and cost",
       %{
         scope: scope,
         project: project,
         work_items: [first_item, second_item] = work_items,
         counterparty: counterparty
       } do
    _approved_budget = approved_project_budget_fixture(scope, project)

    subcontract =
      subcontract_fixture(scope, project, work_items, counterparty, %{
        name: "Obra gris",
        current_contract_amount: "200.0000"
      })

    first_activity = work_activity_fixture(scope, project, first_item)
    second_activity = work_activity_fixture(scope, project, second_item)

    first_progress =
      executed_progress_fixture(scope, project, first_activity, %{quantity: "5.0000"})

    second_progress =
      executed_progress_fixture(scope, project, second_activity, %{quantity: "4.0000"})

    first_control =
      quality_control_fixture(scope, project, first_progress, %{accepted_quantity: "5.0000"})

    second_control =
      quality_control_fixture(scope, project, second_progress, %{
        accepted_quantity: "2.0000",
        rejection_reason: "Fisura visible",
        non_conformity_originated: true
      })

    _non_conformity =
      non_conformity_fixture(scope, project, second_item, %{
        quality_control_id: second_control.id,
        defect: "Fisura visible",
        affected_quantity: "2.0000"
      })

    {:ok, _estimate} =
      Civora.Subcontracts.create_subcontract_estimate(scope, project, subcontract, %{
        quality_control_ids: [first_control.id]
      })

    assert {:ok, report} = Reports.get_internal_project_report(scope, project)

    assert length(report.budget_lines) == 2

    assert Enum.map(report.work_item_progress, & &1.work_item.description) == [
             "Mamposteria",
             "Repello"
           ]

    repello = Enum.find(report.work_item_progress, &(&1.work_item.id == second_item.id))
    assert Decimal.equal?(repello.progress.executed_quantity, Decimal.new("4.0000"))
    assert Decimal.equal?(repello.progress.payable_quantity, Decimal.new("2.0000"))
    assert Decimal.equal?(repello.progress.open_non_conformity_quantity, Decimal.new("2.0000"))

    assert [%{defect: "Fisura visible"}] = report.open_non_conformities
    assert [%{subcontract: %{name: "Obra gris"}}] = report.estimates
    assert Decimal.equal?(report.cost_summary.totals.estimated_amount, Decimal.new("19.6080"))
  end

  test "rejects users outside the project", %{project: project} do
    outsider_scope = user_fixture() |> Scope.for_user()

    assert {:error, :unauthorized} =
             Reports.get_internal_project_report(outsider_scope, project)
  end
end
