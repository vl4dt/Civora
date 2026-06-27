defmodule CivoraWeb.ProjectLiveTest do
  use CivoraWeb.ConnCase

  import Civora.AccountsFixtures
  import Civora.ExecutionFixtures
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
      assert has_element?(view, ~s|a[href="/projects/#{project.id}/subcontracts"]|)

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

    test "creates and edits a historical performance sheet copy", %{conn: conn, scope: scope} do
      project = project_fixture(scope)
      phase = project_phase_fixture(scope, project)
      work_item = work_item_fixture(scope, project, phase, %{description: "Muro presupuestado"})
      source = performance_sheet_fixture(scope, %{name: "Muro reusable"})

      {:ok, view, html} = live(conn, ~p"/projects/#{project}/work-items/#{work_item}")
      assert html =~ "Aun no se ha generado una copia historica"
      assert has_element?(view, "#budgeted-sheet-source-form")

      html =
        view
        |> form("#budgeted-sheet-source-form",
          budgeted_sheet_source: %{source_id: source.id}
        )
        |> render_submit()

      assert html =~ "Ficha presupuestada creada correctamente."
      assert html =~ "Copia de Muro reusable"
      assert has_element?(view, "#budgeted-sheet-form")

      [snapshot] = Civora.Repo.all(Civora.Budget.BudgetedPerformanceSheet)
      snapshot = Civora.Repo.preload(snapshot, :resources)

      resource_params =
        snapshot.resources
        |> Enum.with_index()
        |> Map.new(fn {resource, index} ->
          {to_string(index),
           %{
             id: resource.id,
             category: resource.category,
             name: resource.name,
             unit: resource.unit,
             quantity: if(index == 0, do: "3.5", else: resource.quantity)
           }}
        end)

      html =
        view
        |> form("#budgeted-sheet-form",
          budgeted_performance_sheet: %{
            name: "Muro ajustado para proyecto",
            description: snapshot.description,
            unit: snapshot.unit,
            productivity: snapshot.productivity,
            waste_percentage: "9",
            resources: resource_params
          }
        )
        |> render_submit()

      assert html =~ "Ficha presupuestada actualizada correctamente."
      assert html =~ "Muro ajustado para proyecto"

      persisted_resource =
        snapshot.resources
        |> hd()
        |> then(&Civora.Repo.get!(Civora.Budget.BudgetedPerformanceSheetResource, &1.id))

      assert Decimal.equal?(persisted_resource.quantity, Decimal.new("3.5"))
      assert Civora.Repo.get!(Civora.Budget.PerformanceSheet, source.id).name == "Muro reusable"
    end

    test "read-only project members see the snapshot without edit controls", %{scope: scope} do
      project = project_fixture(scope)
      phase = project_phase_fixture(scope, project)
      work_item = work_item_fixture(scope, project, phase)
      snapshot = budgeted_performance_sheet_fixture(scope, project, work_item)
      viewer = user_fixture()
      assignment_fixture(scope, project, viewer, :consulta)
      viewer_conn = build_conn() |> log_in_user(viewer)

      {:ok, view, html} = live(viewer_conn, ~p"/projects/#{project}/work-items/#{work_item}")
      assert html =~ snapshot.name
      assert html =~ hd(snapshot.resources).name
      refute has_element?(view, "#budgeted-sheet-form")
      refute has_element?(view, "#budgeted-sheet-source-form")
    end

    test "creates and lists work activities from the work item detail", %{
      conn: conn,
      scope: scope
    } do
      project = project_fixture(scope)
      phase = project_phase_fixture(scope, project)
      work_item = work_item_fixture(scope, project, phase, %{description: "Repello fino"})

      {:ok, view, html} = live(conn, ~p"/projects/#{project}/work-items/#{work_item}")

      assert html =~ "Sin actividades registradas"
      assert has_element?(view, "#work-activity-form")

      html =
        view
        |> form("#work-activity-form",
          work_activity: %{
            location_sector: "Nivel 2 / fachada norte",
            description: "Ejecutar repello fino en el tramo principal"
          }
        )
        |> render_submit()

      assert html =~ "Actividad de obra agregada correctamente."
      assert html =~ "Nivel 2 / fachada norte"
      assert html =~ "Ejecutar repello fino"
    end

    test "read-only members inspect work activities without creation controls", %{scope: scope} do
      project = project_fixture(scope)
      phase = project_phase_fixture(scope, project)
      work_item = work_item_fixture(scope, project, phase)
      activity = work_activity_fixture(scope, project, work_item)
      viewer = user_fixture()
      assignment_fixture(scope, project, viewer, :consulta)
      viewer_conn = build_conn() |> log_in_user(viewer)

      {:ok, view, html} = live(viewer_conn, ~p"/projects/#{project}/work-items/#{work_item}")

      assert html =~ activity.location_sector
      refute has_element?(view, "#work-activity-form")
    end

    test "registers executed progress from the work item detail", %{
      conn: conn,
      scope: scope
    } do
      project = project_fixture(scope)
      phase = project_phase_fixture(scope, project)
      work_item = work_item_fixture(scope, project, phase, %{description: "Piso pulido"})

      activity =
        work_activity_fixture(scope, project, work_item, %{
          location_sector: "Nivel 1 / lobby"
        })

      {:ok, view, html} = live(conn, ~p"/projects/#{project}/work-items/#{work_item}")

      assert html =~ "Sin avance ejecutado registrado"
      assert has_element?(view, "#executed-progress-form")

      html =
        view
        |> form("#executed-progress-form",
          executed_progress: %{
            work_activity_id: activity.id,
            quantity: "12.75",
            location_sector: "Nivel 1 / lobby norte"
          }
        )
        |> render_submit()

      assert html =~ "Avance ejecutado registrado correctamente."
      assert html =~ "12.75"
      assert html =~ "m2"
      assert html =~ "Nivel 1 / lobby norte"
      assert html =~ "No pagable"
    end

    test "read-only members inspect executed progress without registration controls", %{
      scope: scope
    } do
      project = project_fixture(scope)
      phase = project_phase_fixture(scope, project)
      work_item = work_item_fixture(scope, project, phase)
      activity = work_activity_fixture(scope, project, work_item)

      progress =
        executed_progress_fixture(scope, project, activity, %{
          quantity: "4.2500",
          location_sector: "Sector terminado"
        })

      viewer = user_fixture()
      assignment_fixture(scope, project, viewer, :consulta)
      viewer_conn = build_conn() |> log_in_user(viewer)

      {:ok, view, html} = live(viewer_conn, ~p"/projects/#{project}/work-items/#{work_item}")

      assert html =~ Decimal.to_string(progress.quantity)
      assert html =~ progress.location_sector
      refute has_element?(view, "#executed-progress-form")
    end
  end

  describe "project budget" do
    test "creates and approves an immutable baseline from project work", %{
      conn: conn,
      scope: scope
    } do
      project = project_fixture(scope, %{name: "Presupuesto Hospital"})
      phase = project_phase_fixture(scope, project, %{name: "Cimentacion"})

      work_item =
        work_item_fixture(scope, project, phase, %{description: "Zapata corrida"})

      sheet = budgeted_performance_sheet_fixture(scope, project, work_item)

      {:ok, view, html} = live(conn, ~p"/projects/#{project}/budget")
      assert html =~ "Presupuesto inicial pendiente"
      assert has_element?(view, "#create-project-budget")

      html = render_click(view, "create_budget")
      assert html =~ "Presupuesto inicial generado correctamente."
      assert html =~ "Zapata corrida"
      assert html =~ sheet.name
      assert has_element?(view, "#approve-project-budget")

      html = render_click(view, "approve_budget")
      assert html =~ "Presupuesto aprobado como linea base inalterable."
      assert html =~ "Linea base aprobada e inalterable"
      refute has_element?(view, "#approve-project-budget")

      {:ok, index_view, index_html} = live(conn, ~p"/projects/#{project}/work-items")
      assert index_html =~ "El presupuesto aprobado es inalterable"
      refute has_element?(index_view, "#work-item-form")

      {:ok, item_view, item_html} = live(conn, ~p"/projects/#{project}/work-items/#{work_item}")
      assert item_html =~ "no admite edicion directa"
      refute has_element?(item_view, "#budgeted-sheet-form")
    end

    test "read-only members inspect a budget without management actions", %{scope: scope} do
      project = project_fixture(scope)
      phase = project_phase_fixture(scope, project)
      work_item = work_item_fixture(scope, project, phase)
      _sheet = budgeted_performance_sheet_fixture(scope, project, work_item)
      budget = project_budget_fixture(scope, project)

      viewer = user_fixture()
      assignment_fixture(scope, project, viewer, :consulta)
      viewer_conn = build_conn() |> log_in_user(viewer)

      {:ok, view, html} = live(viewer_conn, ~p"/projects/#{project}/budget")
      assert html =~ hd(budget.lines).description
      refute has_element?(view, "#approve-project-budget")
      refute has_element?(view, "#create-project-budget")
    end

    test "users outside the project cannot inspect its budget", %{scope: scope} do
      project = project_fixture(scope)
      outsider_conn = build_conn() |> log_in_user(user_fixture())

      assert_raise Ecto.NoResultsError, fn ->
        live(outsider_conn, ~p"/projects/#{project}/budget")
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
