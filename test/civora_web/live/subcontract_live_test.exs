defmodule CivoraWeb.SubcontractLiveTest do
  use CivoraWeb.ConnCase

  import Civora.AccountsFixtures
  import Civora.ExecutionFixtures
  import Civora.ProjectsFixtures
  import Civora.SubcontractsFixtures
  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  setup %{scope: scope} do
    project = project_fixture(scope, %{name: "Proyecto Subcontratado"})
    phase = project_phase_fixture(scope, project)
    first_item = work_item_fixture(scope, project, phase, %{description: "Muro perimetral"})
    second_item = work_item_fixture(scope, project, phase, %{description: "Repello exterior"})
    counterparty = counterparty_fixture(scope, %{name: "Obras Rivera"})

    %{
      project: project,
      work_items: [first_item, second_item],
      counterparty: counterparty
    }
  end

  test "creates, lists, and opens a subcontract with multiple work items", %{
    conn: conn,
    project: project,
    work_items: work_items,
    counterparty: counterparty
  } do
    {:ok, view, html} = live(conn, ~p"/projects/#{project}/subcontracts")
    assert html =~ "Sin subcontratos registrados"
    assert has_element?(view, "#subcontract-form")

    params = %{
      name: "Obra gris exterior",
      counterparty_id: counterparty.id,
      work_item_ids: Enum.map(work_items, & &1.id),
      supply_modality: "mixta",
      current_contract_amount: "250000",
      advance_percentage: "10",
      retention_percentage: "5",
      amortization_percentage: "10"
    }

    {:ok, show, detail} =
      view
      |> form("#subcontract-form", subcontract: params)
      |> render_submit()
      |> follow_redirect(conn)

    assert detail =~ "Subcontrato creado correctamente."
    assert detail =~ "Obra gris exterior"
    assert detail =~ "Obras Rivera"
    assert detail =~ "Mixta"
    assert detail =~ "250000.0000"
    assert detail =~ "Muro perimetral"
    assert detail =~ "Repello exterior"
    assert has_element?(show, ~s|a[href="/projects/#{project.id}/subcontracts"]|)

    {:ok, _index, index_html} = live(conn, ~p"/projects/#{project}/subcontracts")
    assert index_html =~ "Obra gris exterior"
    assert index_html =~ "2 partidas"
  end

  test "read-only members inspect without creation controls", %{
    scope: scope,
    project: project,
    work_items: work_items,
    counterparty: counterparty
  } do
    subcontract = subcontract_fixture(scope, project, work_items, counterparty)
    viewer = user_fixture()
    assignment_fixture(scope, project, viewer, :consulta)
    viewer_conn = build_conn() |> log_in_user(viewer)

    {:ok, view, html} = live(viewer_conn, ~p"/projects/#{project}/subcontracts")
    assert html =~ subcontract.name
    refute has_element?(view, "#subcontract-form")

    {:ok, _show, detail} =
      live(viewer_conn, ~p"/projects/#{project}/subcontracts/#{subcontract}")

    assert detail =~ counterparty.name
  end

  test "shows executed versus payable progress by subcontract work item", %{
    conn: conn,
    scope: scope,
    project: project,
    work_items: [first_item, second_item] = work_items,
    counterparty: counterparty
  } do
    subcontract = subcontract_fixture(scope, project, work_items, counterparty)
    first_activity = work_activity_fixture(scope, project, first_item)
    second_activity = work_activity_fixture(scope, project, second_item)

    first_progress =
      executed_progress_fixture(scope, project, first_activity, %{
        quantity: "8.0000",
        location_sector: "Nivel 1"
      })

    _second_progress =
      executed_progress_fixture(scope, project, second_activity, %{
        quantity: "2.0000",
        location_sector: "Nivel 2"
      })

    control =
      quality_control_fixture(scope, project, first_progress, %{
        accepted_quantity: "5.0000",
        rejection_reason: "Remate incompleto",
        non_conformity_originated: true
      })

    _non_conformity =
      non_conformity_fixture(scope, project, first_item, %{
        quality_control_id: control.id,
        defect: "Remate incompleto",
        location_sector: "Nivel 1",
        responsible_name: "Obras Rivera"
      })

    {:ok, show, html} = live(conn, ~p"/projects/#{project}/subcontracts/#{subcontract}")

    assert html =~ "Avance ejecutado vs pagable"
    assert html =~ "Pagable: 5.0000"
    assert html =~ "Rechazado"
    assert html =~ "3.0000"
    assert html =~ "Ejecutado: 8.0000 m2 / Pagable: 5.0000 m2"
    assert html =~ "Ejecutado: 2.0000 m2 / Pagable: 0.0000 m2"

    assert has_element?(show, "#subcontract-estimate-form")

    html =
      show
      |> form("#subcontract-estimate-form",
        subcontract_estimate: %{quality_control_ids: [control.id]}
      )
      |> render_submit()

    assert html =~ "Estimacion generada correctamente."
    assert html =~ "Estado: Generada"
    assert html =~ "No hay cantidades pagables pendientes de estimar."
  end

  test "users outside the project cannot list or open subcontracts", %{
    scope: scope,
    project: project,
    work_items: work_items,
    counterparty: counterparty
  } do
    subcontract = subcontract_fixture(scope, project, work_items, counterparty)
    outsider_conn = build_conn() |> log_in_user(user_fixture())

    assert_raise Ecto.NoResultsError, fn ->
      live(outsider_conn, ~p"/projects/#{project}/subcontracts")
    end

    assert_raise Ecto.NoResultsError, fn ->
      live(outsider_conn, ~p"/projects/#{project}/subcontracts/#{subcontract}")
    end
  end
end
