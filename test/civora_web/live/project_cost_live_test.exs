defmodule CivoraWeb.ProjectCostLiveTest do
  use CivoraWeb.ConnCase

  import Civora.ExecutionFixtures
  import Civora.ProjectsFixtures
  import Civora.SubcontractsFixtures
  import Civora.AccountsFixtures
  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  setup %{scope: scope} do
    project = project_fixture(scope, %{name: "Proyecto Costo"})
    phase = project_phase_fixture(scope, project)
    first_item = work_item_fixture(scope, project, phase, %{description: "Mamposteria"})
    second_item = work_item_fixture(scope, project, phase, %{description: "Repello"})
    counterparty = counterparty_fixture(scope, %{name: "Obras Rivera"})

    %{
      project: project,
      work_items: [first_item, second_item],
      counterparty: counterparty
    }
  end

  test "shows approved budget, contracted amount, accumulated payable and estimated cost", %{
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

    _second_control =
      quality_control_fixture(scope, project, second_progress, %{accepted_quantity: "4.0000"})

    {:ok, _estimate} =
      Civora.Subcontracts.create_subcontract_estimate(scope, project, subcontract, %{
        quality_control_ids: [first_control.id]
      })

    {:ok, _view, html} = live(conn, ~p"/projects/#{project}/costs")

    assert html =~ "Costo del proyecto"
    assert html =~ "Aprobado (2 partidas)"
    assert html =~ "200.0000"
    assert html =~ "19.6080 / 35.2944"
    assert html =~ "180.3920"
    assert html =~ "Obra gris"
    assert html =~ "Obras Rivera"
  end

  test "shows pending budget and empty subcontract state", %{conn: conn, project: project} do
    {:ok, _view, html} = live(conn, ~p"/projects/#{project}/costs")

    assert html =~ "Pendiente"
    assert html =~ "Sin subcontratos registrados"
  end

  test "users outside the project cannot open project costs", %{project: project} do
    outsider_conn = build_conn() |> log_in_user(user_fixture())

    assert_raise Ecto.NoResultsError, fn ->
      live(outsider_conn, ~p"/projects/#{project}/costs")
    end
  end
end
