defmodule CivoraWeb.ProjectLiveTest do
  use CivoraWeb.ConnCase

  import Civora.AccountsFixtures
  import Civora.ProjectsFixtures
  import Phoenix.LiveViewTest

  alias Civora.Accounts.Scope
  alias Civora.Projects

  setup :register_and_log_in_user

  describe "project index" do
    test "shows the empty state", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Sin proyectos asignados"
      assert html =~ "Nuevo proyecto"
    end

    test "lists only projects assigned to the current user", %{
      conn: conn,
      scope: scope
    } do
      assigned = project_fixture(scope, %{name: "Clinica Norte"})
      other_scope = user_fixture() |> Scope.for_user()
      _private = project_fixture(other_scope, %{name: "Proyecto privado"})

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ assigned.name
      refute html =~ "Proyecto privado"
    end
  end

  describe "new project" do
    test "creates a project and redirects to its detail", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      params = %{
        name: "Centro Logistico",
        client_reference: "Cliente Industrial",
        status: "activo",
        description: "Construccion de centro logistico"
      }

      {:ok, _show_view, html} =
        view
        |> form("#project-form", project: params)
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Centro Logistico"
      assert html =~ "Cliente Industrial"
      assert html =~ "Activo"
      assert html =~ "Sin fases registradas"
    end

    test "validates required fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      html =
        view
        |> form("#project-form", project: %{name: "", client_reference: "", description: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "project detail" do
    test "shows project data and creates a phase for administrators", %{
      conn: conn,
      scope: scope
    } do
      project = project_fixture(scope, %{name: "Torre Central"})
      {:ok, view, html} = live(conn, ~p"/projects/#{project}")

      assert html =~ "Torre Central"
      assert has_element?(view, "#phase-form")
      assert has_element?(view, ~s|a[href="/projects/#{project.id}/audit"]|)
      assert has_element?(view, ~s|a[href="/projects/#{project.id}/work-items"]|)

      html =
        view
        |> form("#phase-form",
          project_phase: %{
            name: "Construccion",
            phase_type: "construccion",
            description: "Ejecucion de estructura y acabados"
          }
        )
        |> render_submit()

      assert html =~ "Fase agregada correctamente."
      assert html =~ "Ejecucion de estructura y acabados"
    end

    test "members with read-only access see detail without the phase form", %{
      scope: administrator_scope,
      user: _administrator
    } do
      project = project_fixture(administrator_scope)
      viewer = user_fixture()
      assignment_fixture(administrator_scope, project, viewer, :consulta)
      viewer_conn = build_conn() |> log_in_user(viewer)

      {:ok, view, html} = live(viewer_conn, ~p"/projects/#{project}")

      assert html =~ project.name
      refute has_element?(view, "#phase-form")
    end

    test "users without an assignment cannot open project detail", %{
      scope: owner_scope
    } do
      project = project_fixture(owner_scope)
      outsider = user_fixture()
      outsider_conn = build_conn() |> log_in_user(outsider)

      assert_raise Ecto.NoResultsError, fn ->
        live(outsider_conn, ~p"/projects/#{project}")
      end
    end

    test "project directors can add phases", %{scope: administrator_scope} do
      project = project_fixture(administrator_scope)
      director = user_fixture()
      assignment_fixture(administrator_scope, project, director, :director_proyecto)
      director_conn = build_conn() |> log_in_user(director)

      {:ok, view, _html} = live(director_conn, ~p"/projects/#{project}")

      assert has_element?(view, "#phase-form")
      assert Projects.authorized?(Scope.for_user(director), project, :manage_project)
    end
  end

  describe "project work items" do
    test "administrator creates, lists, and opens a work item", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Edificio Sur"})
      phase = project_phase_fixture(scope, project, %{name: "Obra gris"})

      {:ok, view, html} = live(conn, ~p"/projects/#{project}/work-items")
      assert html =~ "Sin partidas registradas"
      assert has_element?(view, "#work-item-form")

      html =
        view
        |> form("#work-item-form",
          work_item: %{
            project_phase_id: phase.id,
            description: "Losa de entrepiso",
            unit: "m2",
            quantity: "84.25"
          }
        )
        |> render_submit()

      assert html =~ "Partida agregada correctamente."
      assert html =~ "Losa de entrepiso"
      [item] = Civora.Repo.all(Civora.Budget.WorkItem)

      {:ok, _show, detail} = live(conn, ~p"/projects/#{project}/work-items/#{item}")
      assert detail =~ "Losa de entrepiso"
      assert detail =~ "Obra gris"
      assert detail =~ "84.2500"
      assert detail =~ "m2"
    end

    test "budget members can create and read-only members can only inspect", %{scope: scope} do
      project = project_fixture(scope)
      phase = project_phase_fixture(scope, project)

      budget_user = user_fixture()
      assignment_fixture(scope, project, budget_user, :presupuesto)
      budget_conn = build_conn() |> log_in_user(budget_user)
      {:ok, budget_view, _html} = live(budget_conn, ~p"/projects/#{project}/work-items")
      assert has_element?(budget_view, "#work-item-form")

      viewer = user_fixture()
      assignment_fixture(scope, project, viewer, :consulta)
      item = work_item_fixture(scope, project, phase)
      viewer_conn = build_conn() |> log_in_user(viewer)
      {:ok, viewer_view, html} = live(viewer_conn, ~p"/projects/#{project}/work-items")
      assert html =~ item.description
      refute has_element?(viewer_view, "#work-item-form")
    end

    test "users outside the project cannot list or open work items", %{scope: scope} do
      project = project_fixture(scope)
      phase = project_phase_fixture(scope, project)
      item = work_item_fixture(scope, project, phase)
      outsider_conn = build_conn() |> log_in_user(user_fixture())

      assert_raise Ecto.NoResultsError, fn ->
        live(outsider_conn, ~p"/projects/#{project}/work-items")
      end

      assert_raise Ecto.NoResultsError, fn ->
        live(outsider_conn, ~p"/projects/#{project}/work-items/#{item}")
      end
    end
  end

  describe "project audit" do
    test "members can inspect immutable project events", %{
      conn: conn,
      scope: scope,
      user: user
    } do
      project = project_fixture(scope, %{name: "Proyecto auditado"})
      _phase = project_phase_fixture(scope, project, %{name: "Diseno inicial"})

      {:ok, _view, html} = live(conn, ~p"/projects/#{project}/audit")

      assert html =~ "Auditoria"
      assert html =~ "Proyecto creado"
      assert html =~ "Fase creada"
      assert html =~ user.email
      refute html =~ "Eliminar"
    end

    test "users outside the project cannot inspect its audit", %{scope: owner_scope} do
      project = project_fixture(owner_scope)
      outsider = user_fixture()
      outsider_conn = build_conn() |> log_in_user(outsider)

      assert_raise Ecto.NoResultsError, fn ->
        live(outsider_conn, ~p"/projects/#{project}/audit")
      end
    end
  end
end
