defmodule Civora.EvidenceTest do
  use Civora.DataCase

  import Civora.AccountsFixtures
  import Civora.ExecutionFixtures
  import Civora.ProjectsFixtures

  alias Civora.Accounts.Scope
  alias Civora.Audit.AuditEvent
  alias Civora.Evidence
  alias Civora.Evidence.EvidenceAttachment
  alias Civora.Repo

  setup do
    start_supervised!(Civora.Storage.Test)
    Civora.Storage.Test.reset!()

    user = user_fixture()
    scope = Scope.for_user(user)
    project = project_fixture(scope)
    phase = project_phase_fixture(scope, project)
    work_item = work_item_fixture(scope, project, phase)
    activity = work_activity_fixture(scope, project, work_item)
    progress = executed_progress_fixture(scope, project, activity)
    control = quality_control_fixture(scope, project, progress)
    non_conformity = non_conformity_fixture(scope, project, work_item)

    %{
      user: user,
      scope: scope,
      project: project,
      work_item: work_item,
      progress: progress,
      control: control,
      non_conformity: non_conformity
    }
  end

  test "attaches evidence to executed progress with metadata, storage, and audit", %{
    scope: scope,
    project: project,
    work_item: work_item,
    progress: progress,
    user: user
  } do
    assert {:ok, attachment} =
             Evidence.create_attachment(scope, project, work_item, %{
               executed_progress_entry_id: progress.id,
               body: "jpeg bytes",
               original_filename: "avance.jpg",
               content_type: "image/jpeg"
             })

    assert attachment.status == :valid
    assert attachment.uploaded_by_id == user.id
    assert attachment.executed_progress_entry_id == progress.id
    assert attachment.inserted_at
    assert attachment.object_key =~ "evidence/projects/#{project.id}/work-items/#{work_item.id}"

    object_key = attachment.object_key

    assert %{^object_key => %{body: "jpeg bytes", opts: [content_type: "image/jpeg"]}} =
             Civora.Storage.Test.objects()

    assert Repo.get_by!(AuditEvent,
             action: :evidence_uploaded,
             entity_type: "evidence_attachment",
             entity_id: attachment.id
           )
  end

  test "attaches evidence to quality control and nonconformity", %{
    scope: scope,
    project: project,
    work_item: work_item,
    control: control,
    non_conformity: non_conformity
  } do
    assert {:ok, quality_attachment} =
             Evidence.create_attachment(scope, project, work_item, %{
               quality_control_id: control.id,
               body: "quality pdf",
               original_filename: "control.pdf",
               content_type: "application/pdf"
             })

    assert quality_attachment.quality_control_id == control.id

    assert {:ok, non_conformity_attachment} =
             Evidence.create_attachment(scope, project, work_item, %{
               non_conformity_id: non_conformity.id,
               body: "repair photo",
               original_filename: "correccion.png",
               content_type: "image/png"
             })

    assert non_conformity_attachment.non_conformity_id == non_conformity.id
  end

  test "invalidates evidence instead of deleting it", %{
    scope: scope,
    project: project,
    work_item: work_item,
    control: control,
    user: user
  } do
    {:ok, attachment} =
      Evidence.create_attachment(scope, project, work_item, %{
        quality_control_id: control.id,
        body: "photo",
        original_filename: "aprobada.jpg",
        content_type: "image/jpeg"
      })

    assert {:ok, invalidated} =
             Evidence.invalidate_attachment(scope, project, attachment, %{
               invalidation_reason: "Fotografia reemplazada por una toma mas clara"
             })

    assert invalidated.status == :invalidated
    assert invalidated.invalidated_by_id == user.id
    assert invalidated.invalidated_at
    assert Repo.get!(EvidenceAttachment, attachment.id).status == :invalidated
    assert Repo.aggregate(EvidenceAttachment, :count) == 1

    assert Repo.get_by!(AuditEvent,
             action: :evidence_invalidated,
             entity_type: "evidence_attachment",
             entity_id: attachment.id
           )
  end

  test "rejects evidence linked to records outside the work item", %{
    scope: scope,
    project: project,
    work_item: work_item
  } do
    other_project = project_fixture(scope)
    other_phase = project_phase_fixture(scope, other_project)
    other_item = work_item_fixture(scope, other_project, other_phase)
    other_activity = work_activity_fixture(scope, other_project, other_item)
    other_progress = executed_progress_fixture(scope, other_project, other_activity)

    assert {:error, :not_found} =
             Evidence.create_attachment(scope, project, work_item, %{
               executed_progress_entry_id: other_progress.id,
               body: "bad",
               original_filename: "bad.jpg",
               content_type: "image/jpeg"
             })
  end
end
