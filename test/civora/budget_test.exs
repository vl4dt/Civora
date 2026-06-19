defmodule Civora.BudgetTest do
  use Civora.DataCase

  import Civora.AccountsFixtures
  import Civora.ProjectsFixtures

  alias Civora.Accounts.Scope
  alias Civora.Audit.AuditEvent
  alias Civora.Budget
  alias Civora.Budget.WorkItem
  alias Civora.Repo

  setup do
    administrator = user_fixture()
    scope = Scope.for_user(administrator)
    project = project_fixture(scope)
    phase = project_phase_fixture(scope, project)

    %{scope: scope, project: project, phase: phase}
  end

  describe "work items" do
    test "administrator creates, lists, and fetches a project work item", context do
      assert {:ok, %WorkItem{} = item} =
               Budget.create_work_item(context.scope, context.project, %{
                 project_phase_id: context.phase.id,
                 unit: "m2",
                 quantity: "125.7500",
                 description: "Muro de bloque reforzado"
               })

      assert item.project_id == context.project.id
      assert item.project_phase_id == context.phase.id
      assert Decimal.equal?(item.quantity, Decimal.new("125.75"))
      assert {:ok, [listed]} = Budget.list_work_items(context.scope, context.project)
      assert listed.id == item.id
      assert listed.project_phase.id == context.phase.id
      assert {:ok, fetched} = Budget.get_work_item(context.scope, context.project, item.id)
      assert fetched.description == "Muro de bloque reforzado"
    end

    test "budget role can create while read-only members cannot", context do
      budget_user = user_fixture()
      assignment_fixture(context.scope, context.project, budget_user, :presupuesto)

      attrs = %{
        project_phase_id: context.phase.id,
        unit: "ml",
        quantity: "12",
        description: "Canalizacion electrica"
      }

      assert {:ok, %WorkItem{}} =
               Budget.create_work_item(Scope.for_user(budget_user), context.project, attrs)

      viewer = user_fixture()
      assignment_fixture(context.scope, context.project, viewer, :consulta)

      assert {:error, :unauthorized} =
               Budget.create_work_item(Scope.for_user(viewer), context.project, attrs)

      assert {:ok, [_]} = Budget.list_work_items(Scope.for_user(viewer), context.project)
    end

    test "rejects a phase belonging to another project", context do
      other_scope = user_fixture() |> Scope.for_user()
      other_project = project_fixture(other_scope)
      other_phase = project_phase_fixture(other_scope, other_project)

      assert {:error, changeset} =
               Budget.create_work_item(context.scope, context.project, %{
                 project_phase_id: other_phase.id,
                 unit: "m3",
                 quantity: "4",
                 description: "Fase ajena"
               })

      assert "is invalid" in errors_on(changeset).project_phase_id
      assert Repo.aggregate(WorkItem, :count) == 0
    end

    test "validates required values and a positive quantity", context do
      assert {:error, changeset} =
               Budget.create_work_item(context.scope, context.project, %{
                 project_phase_id: context.phase.id,
                 unit: "",
                 quantity: "0",
                 description: ""
               })

      errors = errors_on(changeset)
      assert "can't be blank" in errors.unit
      assert "must be greater than 0" in errors.quantity
      assert "can't be blank" in errors.description
    end

    test "does not expose work items across projects", context do
      item = work_item_fixture(context.scope, context.project, context.phase)
      outsider_scope = user_fixture() |> Scope.for_user()

      assert {:error, :unauthorized} = Budget.list_work_items(outsider_scope, context.project)

      assert {:error, :not_found} =
               Budget.get_work_item(outsider_scope, context.project, item.id)
    end

    test "creation appends its audit event atomically", context do
      item = work_item_fixture(context.scope, context.project, context.phase)

      event = Repo.get_by!(AuditEvent, action: :work_item_created, entity_id: item.id)
      assert event.project_id == context.project.id
      assert event.actor_id == context.scope.user.id
      assert event.new_state["unit"] == "m2"
      assert event.new_state["project_phase_id"] == context.phase.id
    end
  end
end
