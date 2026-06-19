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
end
