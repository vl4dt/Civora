defmodule Civora.QualityTest do
  use Civora.DataCase

  import Civora.AccountsFixtures
  import Civora.ExecutionFixtures
  import Civora.ProjectsFixtures

  alias Civora.Accounts.Scope
  alias Civora.Audit.AuditEvent
  alias Civora.Quality
  alias Civora.Quality.QualityControl
  alias Civora.Repo

  setup do
    administrator = user_fixture()
    scope = Scope.for_user(administrator)
    project = project_fixture(scope)
    phase = project_phase_fixture(scope, project)
    work_item = work_item_fixture(scope, project, phase, %{description: "Mamposteria"})
    activity = work_activity_fixture(scope, project, work_item)
    progress = executed_progress_fixture(scope, project, activity, %{quantity: "10.0000"})

    %{
      administrator: administrator,
      scope: scope,
      project: project,
      work_item: work_item,
      progress: progress
    }
  end

  test "accepts a full executed progress quantity and marks it payable", context do
    assert {:ok, %QualityControl{} = control} =
             Quality.create_quality_control(
               context.scope,
               context.project,
               context.progress,
               %{accepted_quantity: "10.0000"}
             )

    assert control.status == :accepted
    assert Decimal.equal?(control.accepted_quantity, Decimal.new("10.0000"))
    assert Decimal.equal?(control.rejected_quantity, Decimal.new("0.0000"))
    assert Repo.reload!(context.progress).payable

    assert {:ok, [listed]} =
             Quality.list_work_item_quality_controls(
               context.scope,
               context.project,
               context.work_item
             )

    assert listed.id == control.id
    assert listed.executed_progress_entry.id == context.progress.id
  end

  test "accepts a partial quantity and records rejected quantity with nonconformity origin",
       context do
    assert {:ok, control} =
             Quality.create_quality_control(
               context.scope,
               context.project,
               context.progress,
               %{
                 accepted_quantity: "6.2500",
                 rejection_reason: "Fisuras visibles en el tramo final",
                 non_conformity_originated: true
               }
             )

    assert control.status == :partially_accepted
    assert Decimal.equal?(control.accepted_quantity, Decimal.new("6.2500"))
    assert Decimal.equal?(control.rejected_quantity, Decimal.new("3.7500"))
    assert control.non_conformity_originated
    assert Repo.reload!(context.progress).payable
  end

  test "rejects all quantity and keeps progress not payable", context do
    assert {:ok, control} =
             Quality.create_quality_control(
               context.scope,
               context.project,
               context.progress,
               %{
                 accepted_quantity: "0",
                 rejection_reason: "No cumple plomo minimo",
                 non_conformity_originated: true
               }
             )

    assert control.status == :rejected
    assert Decimal.equal?(control.rejected_quantity, context.progress.quantity)
    refute Repo.reload!(context.progress).payable
  end

  test "requires rejection reason when any quantity is rejected", context do
    assert {:error, changeset} =
             Quality.create_quality_control(
               context.scope,
               context.project,
               context.progress,
               %{accepted_quantity: "5.0000"}
             )

    assert %{rejection_reason: [_]} = errors_on(changeset)
  end

  test "rejects accepted quantity above executed quantity", context do
    assert {:error, :accepted_quantity_exceeds_executed} =
             Quality.create_quality_control(
               context.scope,
               context.project,
               context.progress,
               %{accepted_quantity: "10.0001"}
             )
  end

  test "allows only one quality control per executed progress entry", context do
    assert {:ok, _control} =
             Quality.create_quality_control(
               context.scope,
               context.project,
               context.progress,
               %{accepted_quantity: "10.0000"}
             )

    assert {:error, changeset} =
             Quality.create_quality_control(
               context.scope,
               context.project,
               context.progress,
               %{accepted_quantity: "10.0000"}
             )

    assert %{executed_progress_entry_id: [_]} = errors_on(changeset)
  end

  test "quality role can control quality and read-only members can only inspect", context do
    quality_user = user_fixture()
    assignment_fixture(context.scope, context.project, quality_user, :calidad)
    quality_scope = Scope.for_user(quality_user)

    assert {:ok, %QualityControl{}} =
             Quality.create_quality_control(
               quality_scope,
               context.project,
               context.progress,
               %{accepted_quantity: "10.0000"}
             )

    viewer = user_fixture()
    assignment_fixture(context.scope, context.project, viewer, :consulta)
    viewer_scope = Scope.for_user(viewer)

    assert {:error, :unauthorized} =
             Quality.create_quality_control(
               viewer_scope,
               context.project,
               context.progress,
               %{accepted_quantity: "10.0000"}
             )

    assert {:ok, [_]} =
             Quality.list_work_item_quality_controls(
               viewer_scope,
               context.project,
               context.work_item
             )
  end

  test "users outside the project cannot inspect quality controls", context do
    _control = quality_control_fixture(context.scope, context.project, context.progress)
    outsider_scope = user_fixture() |> Scope.for_user()

    assert {:error, :unauthorized} =
             Quality.list_work_item_quality_controls(
               outsider_scope,
               context.project,
               context.work_item
             )
  end

  test "creation appends audit event atomically", context do
    control =
      quality_control_fixture(context.scope, context.project, context.progress, %{
        accepted_quantity: "0",
        rejection_reason: "Rechazo completo",
        non_conformity_originated: true
      })

    event = Repo.get_by!(AuditEvent, action: :quality_rejected, entity_id: control.id)
    assert event.actor_id == context.administrator.id
    assert event.project_id == context.project.id
    assert event.entity_type == "quality_control"
    assert event.reason == "Rechazo completo"
    assert event.new_state["executed_progress_entry_id"] == context.progress.id
    assert event.new_state["status"] == "rejected"
    assert event.new_state["non_conformity_originated"]
  end
end
