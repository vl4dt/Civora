defmodule Civora.QualityTest do
  use Civora.DataCase

  import Civora.AccountsFixtures
  import Civora.ExecutionFixtures
  import Civora.ProjectsFixtures

  alias Civora.Accounts.Scope
  alias Civora.Audit.AuditEvent
  alias Civora.Quality
  alias Civora.Quality.{NonConformity, QualityControl}
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

  test "creates a nonconformity from rejected quality quantity", context do
    control =
      quality_control_fixture(context.scope, context.project, context.progress, %{
        accepted_quantity: "6.5000",
        rejection_reason: "Acabado incompleto",
        non_conformity_originated: true
      })

    assert {:ok, %NonConformity{} = non_conformity} =
             Quality.create_non_conformity(
               context.scope,
               context.project,
               context.work_item,
               %{
                 quality_control_id: control.id,
                 defect: "Acabado incompleto",
                 location_sector: "Nivel 1 / eje A",
                 responsible_name: "Subcontratista Rivera",
                 due_on: "2026-07-05",
                 disposition: "Corregir acabado y solicitar reinspeccion"
               }
             )

    assert non_conformity.status == :open
    assert non_conformity.quality_control_id == control.id
    assert non_conformity.executed_progress_entry_id == context.progress.id
    assert Decimal.equal?(non_conformity.affected_quantity, Decimal.new("3.5000"))
    assert Repo.reload!(context.progress).payable
  end

  test "creates and lists a work item nonconformity without executed progress", context do
    assert {:ok, non_conformity} =
             Quality.create_non_conformity(
               context.scope,
               context.project,
               context.work_item,
               %{
                 defect: "Despostillado en arista",
                 location_sector: "Nivel 2",
                 responsible_name: "Equipo interno",
                 affected_quantity: "1.0000"
               }
             )

    assert is_nil(non_conformity.quality_control_id)
    assert is_nil(non_conformity.executed_progress_entry_id)

    assert {:ok, [listed]} =
             Quality.list_work_item_non_conformities(
               context.scope,
               context.project,
               context.work_item
             )

    assert listed.id == non_conformity.id
  end

  test "does not create a nonconformity from accepted quality control", context do
    control = quality_control_fixture(context.scope, context.project, context.progress)

    assert {:error, :quality_control_without_rejection} =
             Quality.create_non_conformity(
               context.scope,
               context.project,
               context.work_item,
               %{
                 quality_control_id: control.id,
                 defect: "No debe persistirse",
                 location_sector: "Sector aceptado",
                 responsible_name: "Subcontratista"
               }
             )
  end

  test "quality role can close a nonconformity and close event is audited", context do
    non_conformity =
      non_conformity_fixture(context.scope, context.project, context.work_item, %{
        defect: "Fisura",
        affected_quantity: "2.0000"
      })

    quality_user = user_fixture()
    assignment_fixture(context.scope, context.project, quality_user, :calidad)
    quality_scope = Scope.for_user(quality_user)

    assert {:ok, closed} =
             Quality.close_non_conformity(
               quality_scope,
               context.project,
               non_conformity,
               %{closure_notes: "Reinspeccion aceptada"}
             )

    assert closed.status == :closed
    assert closed.closed_at
    assert closed.closure_notes == "Reinspeccion aceptada"

    event = Repo.get_by!(AuditEvent, action: :non_conformity_closed, entity_id: closed.id)
    assert event.actor_id == quality_user.id
    assert event.previous_state["status"] == "open"
    assert event.new_state["status"] == "closed"
  end

  test "read-only members cannot create or close nonconformities", context do
    non_conformity = non_conformity_fixture(context.scope, context.project, context.work_item)
    viewer = user_fixture()
    assignment_fixture(context.scope, context.project, viewer, :consulta)
    viewer_scope = Scope.for_user(viewer)

    assert {:error, :unauthorized} =
             Quality.create_non_conformity(
               viewer_scope,
               context.project,
               context.work_item,
               %{
                 defect: "No autorizado",
                 location_sector: "Nivel 1",
                 responsible_name: "Subcontratista",
                 affected_quantity: "1.0000"
               }
             )

    assert {:error, :unauthorized} =
             Quality.close_non_conformity(viewer_scope, context.project, non_conformity, %{
               closure_notes: "No autorizado"
             })

    assert {:ok, [_]} =
             Quality.list_work_item_non_conformities(
               viewer_scope,
               context.project,
               context.work_item
             )
  end
end
