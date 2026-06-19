defmodule CivoraWeb.PerformanceSheetLiveTest do
  use CivoraWeb.ConnCase

  import Civora.AccountsFixtures
  import Civora.ProjectsFixtures
  import Phoenix.LiveViewTest

  alias Civora.Accounts.Scope

  setup :register_and_log_in_user

  test "budget-capable user creates, lists, and opens a reusable sheet", %{
    conn: conn,
    scope: scope
  } do
    _project = project_fixture(scope)
    {:ok, view, html} = live(conn, ~p"/performance-sheets")

    assert html =~ "Sin fichas registradas"
    assert has_element?(view, "#performance-sheet-form")

    {:ok, redirected_conn} =
      view
      |> form("#performance-sheet-form",
        performance_sheet: %{
          name: "Piso ceramico",
          description: "Colocacion de piso ceramico con adhesivo",
          unit: "m2",
          productivity: "16",
          waste_percentage: "8",
          resources: %{
            "0" => %{category: "material", name: "Ceramica", unit: "m2", quantity: "1.08"},
            "1" => %{category: "labor", name: "Instalador", unit: "jornal", quantity: "0.5"},
            "2" => %{category: "", name: "", unit: "", quantity: ""}
          }
        }
      )
      |> render_submit()
      |> follow_redirect(conn)

    html = html_response(redirected_conn, 200)

    assert html =~ "Ficha de rendimiento creada correctamente."
    assert html =~ "Piso ceramico"
    assert html =~ ~s|id="performance-sheet-form"|

    refute html =~
             ~r/<input(?=[^>]*name="performance_sheet\[name\]")(?=[^>]*value="Piso ceramico")[^>]*>/

    [sheet] = Civora.Repo.all(Civora.Budget.PerformanceSheet)

    {:ok, _show, detail} = live(conn, ~p"/performance-sheets/#{sheet}")
    assert detail =~ "Colocacion de piso ceramico con adhesivo"
    assert detail =~ "16.0000"
    assert detail =~ "8.0000%"
    assert detail =~ "Ceramica"
    assert detail =~ "Instalador"
  end

  test "internal user without a budget assignment can inspect but not create", %{scope: scope} do
    _project = project_fixture(scope)
    sheet = performance_sheet_fixture(scope)
    viewer = user_fixture()
    viewer_conn = build_conn() |> log_in_user(viewer)

    {:ok, view, html} = live(viewer_conn, ~p"/performance-sheets")
    assert html =~ sheet.name
    refute has_element?(view, "#performance-sheet-form")

    {:ok, _show, detail} = live(viewer_conn, ~p"/performance-sheets/#{sheet}")
    assert detail =~ sheet.description
  end

  test "project budget role can create global sheets", %{scope: administrator_scope} do
    project = project_fixture(administrator_scope)
    budget_user = user_fixture()
    assignment_fixture(administrator_scope, project, budget_user, :presupuesto)
    budget_conn = build_conn() |> log_in_user(budget_user)

    {:ok, view, _html} = live(budget_conn, ~p"/performance-sheets")
    assert has_element?(view, "#performance-sheet-form")
    assert Civora.Budget.can_manage_performance_sheets?(Scope.for_user(budget_user))
  end
end
