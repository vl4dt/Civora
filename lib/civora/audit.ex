defmodule Civora.Audit do
  @moduledoc """
  Append-only, project-scoped records of critical actions.
  """

  import Ecto.Query, warn: false

  alias Civora.Accounts.{Scope, User}
  alias Civora.Audit.AuditEvent
  alias Civora.Projects
  alias Civora.Projects.Project
  alias Civora.Repo

  @action_labels %{
    project_created: "Proyecto creado",
    project_phase_created: "Fase creada",
    project_assignment_created: "Usuario asignado",
    project_assignment_role_changed: "Rol actualizado",
    project_assignment_removed: "Asignacion retirada",
    work_item_created: "Partida creada",
    budget_approved: "Presupuesto aprobado",
    quality_accepted: "Calidad aceptada",
    estimate_created: "Estimacion creada"
  }

  def actions, do: AuditEvent.actions()
  def action_label(action), do: Map.fetch!(@action_labels, action)

  @doc """
  Builds an audit event for insertion inside the transaction that performs the action.
  """
  def event_changeset(%User{} = actor, %Project{} = project, attrs) do
    attrs =
      attrs
      |> Map.put(:actor_id, actor.id)
      |> Map.put(:project_id, project.id)

    AuditEvent.changeset(%AuditEvent{}, attrs)
  end

  @doc """
  Records an event for a project member.

  Domain contexts should call `event_changeset/3` from the same database
  transaction as the critical action whenever possible.
  """
  def record_event(%Scope{user: %User{} = actor} = scope, %Project{} = project, attrs) do
    with true <- Projects.authorized?(scope, project, :view) do
      actor
      |> event_changeset(project, attrs)
      |> Repo.insert()
    else
      false -> {:error, :unauthorized}
    end
  end

  def list_project_events(%Scope{} = scope, %Project{} = project) do
    with true <- Projects.authorized?(scope, project, :view) do
      events =
        from(e in AuditEvent,
          where: e.project_id == ^project.id,
          join: actor in assoc(e, :actor),
          preload: [actor: actor],
          order_by: [desc: e.inserted_at, desc: e.id]
        )
        |> Repo.all()

      {:ok, events}
    else
      false -> {:error, :unauthorized}
    end
  end
end
