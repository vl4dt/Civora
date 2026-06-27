defmodule Civora.Audit.AuditEvent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Accounts.User
  alias Civora.Projects.Project

  @actions [
    :project_created,
    :project_phase_created,
    :project_assignment_created,
    :project_assignment_role_changed,
    :project_assignment_removed,
    :work_item_created,
    :subcontract_created,
    :work_activity_created,
    :executed_progress_created,
    :budget_approved,
    :quality_accepted,
    :estimate_created
  ]

  schema "audit_events" do
    field :action, Ecto.Enum, values: @actions
    field :entity_type, :string
    field :entity_id, :integer
    field :reason, :string
    field :previous_state, :map, default: %{}
    field :new_state, :map, default: %{}

    belongs_to :project, Project
    belongs_to :actor, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def actions, do: @actions

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :project_id,
      :actor_id,
      :action,
      :entity_type,
      :entity_id,
      :reason,
      :previous_state,
      :new_state
    ])
    |> validate_required([:project_id, :actor_id, :action, :entity_type, :entity_id])
    |> validate_length(:entity_type, min: 2, max: 100)
    |> validate_length(:reason, max: 1_000)
    |> validate_number(:entity_id, greater_than: 0)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:actor_id)
    |> check_constraint(:action, name: :audit_events_action_check)
  end
end
