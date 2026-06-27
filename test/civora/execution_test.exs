defmodule Civora.ExecutionTest do
  use Civora.DataCase

  import Civora.AccountsFixtures
  import Civora.ExecutionFixtures
  import Civora.ProjectsFixtures

  alias Civora.Accounts.Scope
  alias Civora.Audit.AuditEvent
  alias Civora.Execution
  alias Civora.Execution.WorkActivity
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
      first = work_activity_fixture(context.scope, context.project, context.work_item)
      second = work_activity_fixture(context.scope, context.project, context.work_item)

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
end
