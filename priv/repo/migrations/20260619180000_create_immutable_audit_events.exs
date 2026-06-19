defmodule Civora.Repo.Migrations.CreateImmutableAuditEvents do
  use Ecto.Migration

  @actions ~w(
    project_created
    project_phase_created
    project_assignment_created
    project_assignment_role_changed
    project_assignment_removed
    budget_approved
    quality_accepted
    estimate_created
  )

  def change do
    execute """
            CREATE FUNCTION prevent_audit_event_mutation()
            RETURNS trigger AS $$
            BEGIN
              RAISE EXCEPTION 'audit events are immutable';
            END;
            $$ LANGUAGE plpgsql;
            """,
            "DROP FUNCTION prevent_audit_event_mutation()"

    create table(:audit_events) do
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :actor_id, references(:users, on_delete: :restrict), null: false
      add :action, :string, null: false
      add :entity_type, :string, null: false
      add :entity_id, :bigint, null: false
      add :reason, :text
      add :previous_state, :map, null: false, default: %{}
      add :new_state, :map, null: false, default: %{}

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:audit_events, [:project_id, :inserted_at])
    create index(:audit_events, [:actor_id])
    create index(:audit_events, [:entity_type, :entity_id])

    create constraint(:audit_events, :audit_events_action_check,
             check: "action IN (#{quoted_values(@actions)})"
           )

    execute """
            CREATE TRIGGER audit_events_immutable
            BEFORE UPDATE OR DELETE ON audit_events
            FOR EACH ROW EXECUTE FUNCTION prevent_audit_event_mutation();
            """,
            "DROP TRIGGER audit_events_immutable ON audit_events"
  end

  defp quoted_values(values), do: Enum.map_join(values, ", ", &"'#{&1}'")
end
