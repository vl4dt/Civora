defmodule Mix.Tasks.Civora.SeedPilotDataset do
  use Mix.Task

  @shortdoc "Seeds the simulated MVP pilot dataset"

  @impl Mix.Task
  def run([]) do
    Mix.Task.run("app.start")

    summary = Civora.PilotDataset.seed!()

    Mix.shell().info("""
    Seeded pilot dataset:
    project_id: #{summary.project_id}
    project_name: #{summary.project_name}
    users: #{summary.users}
    phases: #{summary.phases}
    work_items: #{summary.work_items}
    subcontracts: #{summary.subcontracts}
    executed_progress_entries: #{summary.executed_progress_entries}
    quality_controls: #{summary.quality_controls}
    non_conformities: #{summary.non_conformities}
    subcontract_estimates: #{summary.subcontract_estimates}
    evidence_attachments: #{summary.evidence_attachments}
    audit_events: #{summary.audit_events}
    """)
  end

  def run(_args) do
    Mix.raise("mix civora.seed_pilot_dataset")
  end
end
