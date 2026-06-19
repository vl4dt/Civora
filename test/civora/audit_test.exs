defmodule Civora.AuditTest do
  use Civora.DataCase

  import Civora.AccountsFixtures
  import Civora.ProjectsFixtures

  alias Civora.Accounts.Scope
  alias Civora.Audit
  alias Civora.Audit.AuditEvent
  alias Civora.Projects
  alias Civora.Repo

  describe "critical project actions" do
    test "project creation records actor, date, action, entity, and state" do
      user = user_fixture()
      scope = Scope.for_user(user)
      project = project_fixture(scope, %{name: "Audited project"})

      assert %AuditEvent{} = event = Repo.get_by!(AuditEvent, action: :project_created)
      assert event.actor_id == user.id
      assert event.project_id == project.id
      assert event.entity_type == "project"
      assert event.entity_id == project.id
      assert event.inserted_at
      assert event.new_state["name"] == "Audited project"
    end

    test "phase and assignment changes append project events" do
      administrator = user_fixture()
      scope = Scope.for_user(administrator)
      project = project_fixture(scope)
      phase = project_phase_fixture(scope, project)
      member = user_fixture()
      assignment = assignment_fixture(scope, project, member, :consulta)

      assert {:ok, assignment} =
               Projects.update_assignment_role(scope, assignment, :calidad)

      assert {:ok, _removed} = Projects.remove_assignment(scope, assignment)

      assert {:ok, events} = Audit.list_project_events(scope, project)
      actions = Enum.map(events, & &1.action)

      assert :project_phase_created in actions
      assert :project_assignment_created in actions
      assert :project_assignment_role_changed in actions
      assert :project_assignment_removed in actions

      phase_event = Enum.find(events, &(&1.action == :project_phase_created))
      assert phase_event.entity_id == phase.id

      role_event = Enum.find(events, &(&1.action == :project_assignment_role_changed))
      assert role_event.previous_state["role"] == "consulta"
      assert role_event.new_state["role"] == "calidad"
    end

    test "failed actions do not append audit events" do
      scope = user_fixture() |> Scope.for_user()

      assert {:error, _changeset} = Projects.create_project(scope, %{name: ""})
      assert Repo.aggregate(AuditEvent, :count) == 0
    end
  end

  describe "future critical action contracts" do
    test "supports budget, quality, and estimation events" do
      scope = user_fixture() |> Scope.for_user()
      project = project_fixture(scope)

      for {action, entity_type, entity_id} <- [
            {:budget_approved, "budget", 101},
            {:quality_accepted, "quality_control", 102},
            {:estimate_created, "estimate", 103}
          ] do
        assert {:ok, %AuditEvent{action: ^action}} =
                 Audit.record_event(scope, project, %{
                   action: action,
                   entity_type: entity_type,
                   entity_id: entity_id,
                   reason: "Automated contract test"
                 })
      end
    end

    test "rejects events from users outside the project" do
      owner_scope = user_fixture() |> Scope.for_user()
      project = project_fixture(owner_scope)
      outsider_scope = user_fixture() |> Scope.for_user()

      assert {:error, :unauthorized} =
               Audit.record_event(outsider_scope, project, %{
                 action: :budget_approved,
                 entity_type: "budget",
                 entity_id: 1
               })

      assert {:error, :unauthorized} = Audit.list_project_events(outsider_scope, project)
    end
  end

  describe "immutability" do
    setup do
      scope = user_fixture() |> Scope.for_user()
      project = project_fixture(scope)
      event = Repo.get_by!(AuditEvent, project_id: project.id, action: :project_created)
      %{event: event}
    end

    test "database rejects updates", %{event: event} do
      assert_raise Postgrex.Error, ~r/audit events are immutable/, fn ->
        Repo.update_all(from(e in AuditEvent, where: e.id == ^event.id),
          set: [reason: "tampered"]
        )
      end
    end

    test "database rejects deletes", %{event: event} do
      assert_raise Postgrex.Error, ~r/audit events are immutable/, fn ->
        Repo.delete_all(from(e in AuditEvent, where: e.id == ^event.id))
      end
    end
  end
end
