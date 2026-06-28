defmodule Civora.ExecutionTest do
  use Civora.DataCase

  import Civora.AccountsFixtures
  import Civora.ExecutionFixtures
  import Civora.ProjectsFixtures

  alias Civora.Accounts.Scope
  alias Civora.Audit.AuditEvent
  alias Civora.Execution
  alias Civora.Execution.{ExecutedProgressEntry, WorkActivity}
  alias Civora.Repo

  setup do
    administrator = user_fixture()
    scope = Scope.for_user(administrator)
    project = project_fixture(scope)
    phase = project_phase_fixture(scope, project)
    work_item = work_item_fixture(scope, project, phase, %{description: "Mamposteria"})

    %{
      administrator: administrator,
      scope: scope,
      project: project,
      work_item: work_item
    }
  end

  describe "work activities" do
    test "creates, lists, and fetches project work activities", context do
      assert {:ok, %WorkActivity{} = activity} =
               Execution.create_work_activity(
                 context.scope,
                 context.project,
                 context.work_item,
                 %{
                   location_sector: "Nivel 1 / eje A-C",
                   description: "Levantar mamposteria del primer sector"
                 }
               )

      assert activity.project_id == context.project.id
      assert activity.work_item_id == context.work_item.id

      assert {:ok, [listed]} = Execution.list_work_activities(context.scope, context.project)
      assert listed.id == activity.id
      assert listed.work_item.description == "Mamposteria"

      assert {:ok, [for_item]} =
               Execution.list_work_item_activities(
                 context.scope,
                 context.project,
                 context.work_item
               )

      assert for_item.id == activity.id

      assert {:ok, fetched} =
               Execution.get_work_activity(context.scope, context.project, activity.id)

      assert fetched.id == activity.id
      assert fetched.work_item.id == context.work_item.id
    end

    test "a work item can have many activities", context do
      first =
        work_activity_fixture(context.scope, context.project, context.work_item, %{
          location_sector: "Nivel 1 / eje A"
        })

      second =
        work_activity_fixture(context.scope, context.project, context.work_item, %{
          location_sector: "Nivel 1 / eje B"
        })

      assert {:ok, activities} =
               Execution.list_work_item_activities(
                 context.scope,
                 context.project,
                 context.work_item
               )

      assert Enum.map(activities, & &1.id) == [first.id, second.id]
    end

    test "validates required fields and lengths", context do
      assert {:error, changeset} =
               Execution.create_work_activity(
                 context.scope,
                 context.project,
                 context.work_item,
                 %{
                   location_sector: "",
                   description: ""
                 }
               )

      assert %{location_sector: [_], description: [_]} = errors_on(changeset)
    end

    test "rejects a work item from another project", context do
      other_scope = user_fixture() |> Scope.for_user()
      other_project = project_fixture(other_scope)
      other_phase = project_phase_fixture(other_scope, other_project)
      other_item = work_item_fixture(other_scope, other_project, other_phase)

      assert {:error, :not_found} =
               Execution.create_work_activity(context.scope, context.project, other_item, %{
                 location_sector: "Sector ajeno",
                 description: "No pertenece al proyecto"
               })
    end

    test "administrators and directors can create, read-only members can only inspect", context do
      director = user_fixture()
      assignment_fixture(context.scope, context.project, director, :director_proyecto)
      director_scope = Scope.for_user(director)

      assert {:ok, %WorkActivity{}} =
               Execution.create_work_activity(
                 director_scope,
                 context.project,
                 context.work_item,
                 %{
                   location_sector: "Frente norte",
                   description: "Actividad creada por direccion"
                 }
               )

      viewer = user_fixture()
      assignment_fixture(context.scope, context.project, viewer, :consulta)
      viewer_scope = Scope.for_user(viewer)

      assert {:error, :unauthorized} =
               Execution.create_work_activity(viewer_scope, context.project, context.work_item, %{
                 location_sector: "Frente sur",
                 description: "No debe persistirse"
               })

      assert {:ok, [_]} =
               Execution.list_work_item_activities(
                 viewer_scope,
                 context.project,
                 context.work_item
               )
    end

    test "users outside the project cannot list or fetch activities", context do
      activity = work_activity_fixture(context.scope, context.project, context.work_item)
      outsider_scope = user_fixture() |> Scope.for_user()

      assert {:error, :unauthorized} =
               Execution.list_work_item_activities(
                 outsider_scope,
                 context.project,
                 context.work_item
               )

      assert {:error, :unauthorized} =
               Execution.get_work_activity(outsider_scope, context.project, activity.id)
    end

    test "creation appends its audit event atomically", context do
      activity = work_activity_fixture(context.scope, context.project, context.work_item)

      event = Repo.get_by!(AuditEvent, action: :work_activity_created, entity_id: activity.id)
      assert event.actor_id == context.administrator.id
      assert event.project_id == context.project.id
      assert event.entity_type == "work_activity"
      assert event.new_state["work_item_id"] == context.work_item.id
      assert event.new_state["location_sector"] == activity.location_sector
    end
  end

  describe "executed progress" do
    setup context do
      activity =
        work_activity_fixture(context.scope, context.project, context.work_item, %{
          location_sector: "Nivel 1 / eje A-C"
        })

      Map.put(context, :activity, activity)
    end

    test "creates and lists executed progress linked to activity and work item", context do
      assert {:ok, %ExecutedProgressEntry{} = entry} =
               Execution.create_executed_progress(
                 context.scope,
                 context.project,
                 context.activity,
                 %{
                   quantity: "8.7500",
                   location_sector: "Nivel 1 / eje A-C",
                   payable: true
                 }
               )

      assert entry.project_id == context.project.id
      assert entry.work_item_id == context.work_item.id
      assert entry.work_activity_id == context.activity.id
      refute entry.payable

      assert {:ok, [listed]} = Execution.list_executed_progress(context.scope, context.project)
      assert listed.id == entry.id
      assert listed.work_activity.id == context.activity.id
      assert listed.work_item.id == context.work_item.id

      assert {:ok, [for_activity]} =
               Execution.list_activity_executed_progress(
                 context.scope,
                 context.project,
                 context.activity
               )

      assert for_activity.id == entry.id

      assert {:ok, [for_item]} =
               Execution.list_work_item_executed_progress(
                 context.scope,
                 context.project,
                 context.work_item
               )

      assert for_item.id == entry.id
      assert for_item.work_activity.id == context.activity.id
    end

    test "validates quantity and reported location", context do
      assert {:error, changeset} =
               Execution.create_executed_progress(
                 context.scope,
                 context.project,
                 context.activity,
                 %{
                   quantity: "0",
                   location_sector: ""
                 }
               )

      assert %{quantity: [_], location_sector: [_]} = errors_on(changeset)
    end

    test "rejects an activity from another project", context do
      other_scope = user_fixture() |> Scope.for_user()
      other_project = project_fixture(other_scope)
      other_phase = project_phase_fixture(other_scope, other_project)
      other_item = work_item_fixture(other_scope, other_project, other_phase)
      other_activity = work_activity_fixture(other_scope, other_project, other_item)

      assert {:error, :not_found} =
               Execution.create_executed_progress(
                 context.scope,
                 context.project,
                 other_activity,
                 %{
                   quantity: "3.0000",
                   location_sector: "Sector ajeno"
                 }
               )
    end

    test "administrators and directors can create, read-only members can only inspect", context do
      director = user_fixture()
      assignment_fixture(context.scope, context.project, director, :director_proyecto)
      director_scope = Scope.for_user(director)

      assert {:ok, %ExecutedProgressEntry{}} =
               Execution.create_executed_progress(
                 director_scope,
                 context.project,
                 context.activity,
                 %{quantity: "2.0000", location_sector: "Frente norte"}
               )

      viewer = user_fixture()
      assignment_fixture(context.scope, context.project, viewer, :consulta)
      viewer_scope = Scope.for_user(viewer)

      assert {:error, :unauthorized} =
               Execution.create_executed_progress(
                 viewer_scope,
                 context.project,
                 context.activity,
                 %{quantity: "2.0000", location_sector: "Frente sur"}
               )

      assert {:ok, [_]} =
               Execution.list_activity_executed_progress(
                 viewer_scope,
                 context.project,
                 context.activity
               )
    end

    test "users outside the project cannot list executed progress", context do
      _entry = executed_progress_fixture(context.scope, context.project, context.activity)
      outsider_scope = user_fixture() |> Scope.for_user()

      assert {:error, :unauthorized} =
               Execution.list_activity_executed_progress(
                 outsider_scope,
                 context.project,
                 context.activity
               )
    end

    test "creation appends its audit event atomically", context do
      entry = executed_progress_fixture(context.scope, context.project, context.activity)

      event = Repo.get_by!(AuditEvent, action: :executed_progress_created, entity_id: entry.id)
      assert event.actor_id == context.administrator.id
      assert event.project_id == context.project.id
      assert event.entity_type == "executed_progress"
      assert event.new_state["work_item_id"] == context.work_item.id
      assert event.new_state["work_activity_id"] == context.activity.id
      assert event.new_state["quantity"] == Decimal.to_string(entry.quantity, :normal)
      refute event.new_state["payable"]
    end
  end
end
