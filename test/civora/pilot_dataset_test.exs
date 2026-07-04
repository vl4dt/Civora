defmodule Civora.PilotDatasetTest do
  use Civora.DataCase

  import Ecto.Query

  alias Civora.Accounts.Scope
  alias Civora.Audit.AuditEvent
  alias Civora.Budget.{ProjectBudget, WorkItem}
  alias Civora.Evidence.EvidenceAttachment
  alias Civora.Execution.ExecutedProgressEntry
  alias Civora.PilotDataset
  alias Civora.Projects.{Project, ProjectAssignment, ProjectPhase}
  alias Civora.Quality.{NonConformity, QualityControl}
  alias Civora.Repo
  alias Civora.Reports
  alias Civora.Subcontracts.{Counterparty, Subcontract, SubcontractEstimate}

  setup do
    start_supervised!(Civora.Storage.Test)
    Civora.Storage.Test.reset!()
    :ok
  end

  test "loads the simulated MVP pilot dataset" do
    assert {:ok, summary} = PilotDataset.seed()

    project = Repo.get!(Project, summary.project_id)
    admin = Civora.Accounts.get_user_by_email("piloto.admin@civora.test")
    scope = Scope.for_user(admin)

    assert project.name == "MVP Piloto Simulado - Residencial Las Palmas"
    assert summary.users == 6
    assert summary.phases == 1
    assert summary.work_items == 4
    assert summary.subcontracts == 2
    assert summary.executed_progress_entries == 8
    assert summary.quality_controls == 8
    assert summary.non_conformities == 1
    assert summary.subcontract_estimates == 2
    assert summary.evidence_attachments == 3
    assert summary.audit_events >= 20

    assert Repo.aggregate(Project, :count) == 1
    assert Repo.aggregate(ProjectPhase, :count) == 1
    assert Repo.aggregate(WorkItem, :count) == 4
    assert Repo.aggregate(Subcontract, :count) == 2
    assert Repo.aggregate(ExecutedProgressEntry, :count) == 8
    assert Repo.aggregate(QualityControl, :count) == 8
    assert Repo.aggregate(NonConformity, :count) == 1
    assert Repo.aggregate(SubcontractEstimate, :count) == 2
    assert Repo.aggregate(EvidenceAttachment, :count) == 3
    assert Repo.aggregate(Counterparty, :count) == 2

    assert Repo.aggregate(
             from(a in ProjectAssignment, where: a.project_id == ^project.id),
             :count
           ) == 6

    assert Repo.one!(
             from(b in ProjectBudget, where: b.project_id == ^project.id, select: b.status)
           ) == :approved

    progress_counts =
      from(e in ExecutedProgressEntry,
        group_by: e.work_item_id,
        select: {e.work_item_id, count(e.id)}
      )
      |> Repo.all()
      |> Map.new()

    assert Map.values(progress_counts) |> Enum.sort() == [2, 2, 2, 2]

    assert Repo.exists?(
             from(a in AuditEvent,
               where: a.project_id == ^project.id and a.action == :budget_approved
             )
           )

    assert Repo.exists?(
             from(a in AuditEvent,
               where: a.project_id == ^project.id and a.action == :estimate_created
             )
           )

    assert Repo.exists?(
             from(a in AuditEvent,
               where: a.project_id == ^project.id and a.action == :evidence_uploaded
             )
           )

    assert {:ok, report} = Reports.get_internal_project_report(scope, project)
    assert length(report.budget_lines) == 4
    assert length(report.work_item_progress) == 4
    assert length(report.open_non_conformities) == 1
    assert length(report.estimates) == 2
    assert Decimal.gt?(report.cost_summary.totals.estimated_amount, Decimal.new("0"))
  end

  test "can be rerun without duplicating the pilot dataset" do
    assert {:ok, first_summary} = PilotDataset.seed()
    first_counts = pilot_counts(first_summary.project_id)
    first_objects = Civora.Storage.Test.objects()

    assert {:ok, second_summary} = PilotDataset.seed()
    second_counts = pilot_counts(second_summary.project_id)

    assert second_summary.project_id == first_summary.project_id
    assert second_counts == first_counts
    assert Civora.Storage.Test.objects() == first_objects
  end

  defp pilot_counts(project_id) do
    %{
      projects: Repo.aggregate(Project, :count),
      phases: Repo.aggregate(from(p in ProjectPhase, where: p.project_id == ^project_id), :count),
      assignments:
        Repo.aggregate(from(a in ProjectAssignment, where: a.project_id == ^project_id), :count),
      work_items: Repo.aggregate(from(w in WorkItem, where: w.project_id == ^project_id), :count),
      subcontracts:
        Repo.aggregate(from(s in Subcontract, where: s.project_id == ^project_id), :count),
      progress:
        Repo.aggregate(
          from(e in ExecutedProgressEntry, where: e.project_id == ^project_id),
          :count
        ),
      quality:
        Repo.aggregate(from(c in QualityControl, where: c.project_id == ^project_id), :count),
      non_conformities:
        Repo.aggregate(from(n in NonConformity, where: n.project_id == ^project_id), :count),
      estimates:
        Repo.aggregate(from(e in SubcontractEstimate, where: e.project_id == ^project_id), :count),
      evidence:
        Repo.aggregate(from(a in EvidenceAttachment, where: a.project_id == ^project_id), :count),
      audit: Repo.aggregate(from(a in AuditEvent, where: a.project_id == ^project_id), :count)
    }
  end
end
