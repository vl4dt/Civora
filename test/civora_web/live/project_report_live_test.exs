defmodule CivoraWeb.ProjectReportLiveTest do
  use CivoraWeb.ConnCase

  import Civora.AccountsFixtures
  import Civora.ExecutionFixtures
  import Civora.ProjectsFixtures
  import Civora.SubcontractsFixtures
  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  setup %{scope: scope} do
    project = project_fixture(scope, %{name: "Proyecto Reporte"})
    phase = project_phase_fixture(scope, project, %{name: "Construccion"})
    first_item = work_item_fixture(scope, project, phase, %{description: "Mamposteria"})
    second_item = work_item_fixture(scope, project, phase, %{description: "Repello"})
    counterparty = counterparty_fixture(scope, %{name: "Obras Rivera"})

    %{
      project: project,
      work_items: [first_item, second_item],
      counterparty: counterparty
    }
  end

  test "shows budgeted items, progress, open nonconformities, estimates and accumulated cost",
       %{
         conn: conn,
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
        affected_quantity: "2.0000",
        responsible_name: "Obras Rivera"
      })

    {:ok, _estimate} =
      Civora.Subcontracts.create_subcontract_estimate(scope, project, subcontract, %{
        quality_control_ids: [first_control.id]
      })

    {:ok, _view, html} = live(conn, ~p"/projects/#{project}/report")

    assert html =~ "Reporte interno"
    assert html =~ "Partidas presupuestadas"
    assert html =~ "Mamposteria"
    assert html =~ "Repello"
    assert html =~ "5.0000 m2"
    assert html =~ "2.0000 m2"
    assert html =~ "No conformidades abiertas"
    assert html =~ "Fisura visible"
    assert html =~ "Obras Rivera"
    assert html =~ "Estimaciones y costo acumulado"
    assert html =~ "19.6080"
    assert html =~ "180.3920"
  end

  test "shows empty report states without an approved budget or estimates", %{
    conn: conn,
    project: project
  } do
    {:ok, _view, html} = live(conn, ~p"/projects/#{project}/report")

    assert html =~ "Sin presupuesto aprobado"
    assert html =~ "Sin no conformidades abiertas"
    assert html =~ "Sin estimaciones generadas"
  end

  test "project page links to the internal report", %{conn: conn, project: project} do
    {:ok, _view, html} = live(conn, ~p"/projects/#{project}")

    assert html =~ "Reporte"
    assert html =~ ~p"/projects/#{project}/report"
  end

  test "users outside the project cannot open the internal report", %{project: project} do
    outsider_conn = build_conn() |> log_in_user(user_fixture())

    assert_raise Ecto.NoResultsError, fn ->
      live(outsider_conn, ~p"/projects/#{project}/report")
    end
  end
end
