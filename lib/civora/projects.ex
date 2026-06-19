defmodule Civora.Projects do
  @moduledoc """
  Project membership and project-scoped authorization.

  Projects include their basic commercial identity and optional contracted phases.
  """

  import Ecto.Query, warn: false

  alias Civora.Accounts.{Scope, User}
  alias Civora.Audit
  alias Civora.Projects.{Project, ProjectAssignment, ProjectPhase}
  alias Civora.Repo

  @role_labels %{
    administrador: "Administrador",
    director_proyecto: "Director de proyecto",
    presupuesto: "Presupuesto",
    calidad: "Calidad",
    finanzas: "Finanzas",
    consulta: "Consulta"
  }

  @status_labels %{
    planificacion: "Planificacion",
    activo: "Activo",
    pausado: "Pausado",
    cerrado: "Cerrado",
    cancelado: "Cancelado"
  }

  @phase_type_labels %{
    diseno: "Diseno",
    presupuesto: "Presupuesto",
    planificacion: "Planificacion",
    construccion: "Construccion",
    supervision: "Supervision",
    cierre: "Cierre"
  }

  def available_roles, do: ProjectAssignment.roles()
  def role_label(role), do: Map.fetch!(@role_labels, role)
  def available_statuses, do: Project.statuses()
  def status_label(status), do: Map.fetch!(@status_labels, status)
  def available_phase_types, do: ProjectPhase.types()
  def phase_type_label(type), do: Map.fetch!(@phase_type_labels, type)

  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  def change_project_phase(%ProjectPhase{} = phase, attrs \\ %{}) do
    ProjectPhase.changeset(phase, attrs)
  end

  @doc """
  Creates a project and makes its creator the first administrator.
  """
  def create_project(%Scope{user: %User{} = user}, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:project, Project.changeset(%Project{}, attrs))
    |> Ecto.Multi.insert(:assignment, fn %{project: project} ->
      ProjectAssignment.changeset(%ProjectAssignment{}, %{
        project_id: project.id,
        user_id: user.id,
        role: :administrador
      })
    end)
    |> Ecto.Multi.insert(:audit_event, fn %{project: project} ->
      Audit.event_changeset(user, project, %{
        action: :project_created,
        entity_type: "project",
        entity_id: project.id,
        new_state: project_state(project)
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{project: project}} -> {:ok, project}
      {:error, :project, changeset, _changes} -> {:error, changeset}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  def list_projects(%Scope{user: %User{id: user_id}}) do
    from(p in Project,
      join: a in ProjectAssignment,
      on: a.project_id == p.id,
      where: a.user_id == ^user_id,
      order_by: [asc: p.name]
    )
    |> Repo.all()
  end

  def get_project(%Scope{user: %User{id: user_id}}, project_id) do
    from(p in Project,
      join: a in ProjectAssignment,
      on: a.project_id == p.id,
      where: p.id == ^project_id and a.user_id == ^user_id
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      project -> {:ok, project}
    end
  end

  def list_project_phases(%Scope{} = scope, %Project{} = project) do
    with true <- authorized?(scope, project, :view) do
      phases =
        from(p in ProjectPhase,
          where: p.project_id == ^project.id,
          order_by: [asc: p.inserted_at, asc: p.name]
        )
        |> Repo.all()

      {:ok, phases}
    else
      false -> {:error, :unauthorized}
    end
  end

  def create_project_phase(%Scope{user: %User{} = actor} = scope, %Project{} = project, attrs) do
    with true <- authorized?(scope, project, :manage_project) do
      attrs = put_project_id(attrs, project.id)

      Ecto.Multi.new()
      |> Ecto.Multi.insert(:phase, ProjectPhase.changeset(%ProjectPhase{}, attrs))
      |> Ecto.Multi.insert(:audit_event, fn %{phase: phase} ->
        Audit.event_changeset(actor, project, %{
          action: :project_phase_created,
          entity_type: "project_phase",
          entity_id: phase.id,
          new_state: phase_state(phase)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{phase: phase}} -> {:ok, phase}
        {:error, :phase, changeset, _changes} -> {:error, changeset}
        {:error, _operation, reason, _changes} -> {:error, reason}
      end
    else
      false -> {:error, :unauthorized}
    end
  end

  def list_project_assignments(%Scope{} = scope, %Project{} = project) do
    with true <- authorized?(scope, project, :view) do
      assignments =
        from(a in ProjectAssignment,
          where: a.project_id == ^project.id,
          join: u in assoc(a, :user),
          preload: [user: u],
          order_by: [asc: u.email]
        )
        |> Repo.all()

      {:ok, assignments}
    else
      false -> {:error, :unauthorized}
    end
  end

  def assign_user(
        %Scope{user: %User{} = actor} = scope,
        %Project{} = project,
        %User{} = user,
        role
      ) do
    with true <- authorized?(scope, project, :manage_assignments) do
      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :assignment,
        ProjectAssignment.changeset(%ProjectAssignment{}, %{
          project_id: project.id,
          user_id: user.id,
          role: role
        })
      )
      |> Ecto.Multi.insert(:audit_event, fn %{assignment: assignment} ->
        Audit.event_changeset(actor, project, %{
          action: :project_assignment_created,
          entity_type: "project_assignment",
          entity_id: assignment.id,
          new_state: assignment_state(assignment)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{assignment: assignment}} -> {:ok, assignment}
        {:error, :assignment, changeset, _changes} -> {:error, changeset}
        {:error, _operation, reason, _changes} -> {:error, reason}
      end
    else
      false -> {:error, :unauthorized}
    end
  end

  def update_assignment_role(
        %Scope{user: %User{} = actor} = scope,
        %ProjectAssignment{} = assignment,
        role
      ) do
    Repo.transaction(fn ->
      locked_assignment = lock_assignment!(assignment.id)
      project = lock_project!(locked_assignment.project_id)

      unless authorized?(scope, locked_assignment.project_id, :manage_assignments) do
        Repo.rollback(:unauthorized)
      end

      if removing_last_administrator?(locked_assignment, role) do
        Repo.rollback(:last_administrator)
      end

      previous_state = assignment_state(locked_assignment)

      locked_assignment
      |> ProjectAssignment.role_changeset(%{role: role})
      |> Repo.update()
      |> case do
        {:ok, updated_assignment} ->
          insert_audit_event!(actor, project, %{
            action: :project_assignment_role_changed,
            entity_type: "project_assignment",
            entity_id: updated_assignment.id,
            previous_state: previous_state,
            new_state: assignment_state(updated_assignment)
          })

          updated_assignment

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def remove_assignment(
        %Scope{user: %User{} = actor} = scope,
        %ProjectAssignment{} = assignment
      ) do
    Repo.transaction(fn ->
      locked_assignment = lock_assignment!(assignment.id)
      project = lock_project!(locked_assignment.project_id)

      unless authorized?(scope, locked_assignment.project_id, :manage_assignments) do
        Repo.rollback(:unauthorized)
      end

      if last_administrator?(locked_assignment) do
        Repo.rollback(:last_administrator)
      end

      previous_state = assignment_state(locked_assignment)
      removed_assignment = Repo.delete!(locked_assignment)

      insert_audit_event!(actor, project, %{
        action: :project_assignment_removed,
        entity_type: "project_assignment",
        entity_id: removed_assignment.id,
        previous_state: previous_state
      })

      removed_assignment
    end)
  end

  def authorized?(%Scope{user: %User{id: user_id}}, %Project{id: project_id}, action) do
    authorized?(%Scope{user: %User{id: user_id}}, project_id, action)
  end

  def authorized?(%Scope{user: %User{id: user_id}}, project_id, :view) do
    Repo.exists?(
      from(a in ProjectAssignment,
        where: a.project_id == ^project_id and a.user_id == ^user_id
      )
    )
  end

  def authorized?(%Scope{user: %User{id: user_id}}, project_id, :manage_assignments) do
    Repo.exists?(
      from(a in ProjectAssignment,
        where:
          a.project_id == ^project_id and a.user_id == ^user_id and
            a.role == :administrador
      )
    )
  end

  def authorized?(%Scope{user: %User{id: user_id}}, project_id, :manage_project) do
    Repo.exists?(
      from(a in ProjectAssignment,
        where:
          a.project_id == ^project_id and a.user_id == ^user_id and
            a.role in [:administrador, :director_proyecto]
      )
    )
  end

  def authorized?(%Scope{user: %User{id: user_id}}, project_id, :manage_budget) do
    Repo.exists?(
      from(a in ProjectAssignment,
        where:
          a.project_id == ^project_id and a.user_id == ^user_id and
            a.role in [:administrador, :director_proyecto, :presupuesto]
      )
    )
  end

  def authorized?(_scope, _project, _action), do: false

  defp lock_assignment!(assignment_id) do
    Repo.one!(from(a in ProjectAssignment, where: a.id == ^assignment_id, lock: "FOR UPDATE"))
  end

  defp put_project_id(attrs, project_id) do
    if Enum.any?(Map.keys(attrs), &is_binary/1) do
      Map.put(attrs, "project_id", project_id)
    else
      Map.put(attrs, :project_id, project_id)
    end
  end

  defp lock_project!(project_id) do
    Repo.one!(from(p in Project, where: p.id == ^project_id, lock: "FOR UPDATE"))
  end

  defp removing_last_administrator?(%ProjectAssignment{role: :administrador} = assignment, role)
       when role != :administrador do
    last_administrator?(assignment)
  end

  defp removing_last_administrator?(_assignment, _role), do: false

  defp last_administrator?(%ProjectAssignment{role: :administrador, project_id: project_id}) do
    Repo.aggregate(
      from(a in ProjectAssignment,
        where: a.project_id == ^project_id and a.role == :administrador
      ),
      :count
    ) == 1
  end

  defp last_administrator?(_assignment), do: false

  defp insert_audit_event!(actor, project, attrs) do
    actor
    |> Audit.event_changeset(project, attrs)
    |> Repo.insert!()
  end

  defp project_state(project) do
    %{
      "name" => project.name,
      "client_reference" => project.client_reference,
      "status" => to_string(project.status),
      "description" => project.description
    }
  end

  defp phase_state(phase) do
    %{
      "name" => phase.name,
      "phase_type" => to_string(phase.phase_type),
      "description" => phase.description
    }
  end

  defp assignment_state(assignment) do
    %{
      "user_id" => assignment.user_id,
      "role" => to_string(assignment.role)
    }
  end
end
