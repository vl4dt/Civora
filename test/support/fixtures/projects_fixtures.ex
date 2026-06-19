defmodule Civora.ProjectsFixtures do
  @moduledoc """
  Test helpers for project identities and project assignments.
  """

  alias Civora.Projects

  def unique_project_name, do: "Project #{System.unique_integer([:positive])}"

  def project_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: unique_project_name(),
        client_reference: "Cliente de prueba",
        status: :planificacion,
        description: "Proyecto para pruebas automatizadas"
      })

    {:ok, project} = Projects.create_project(scope, attrs)
    project
  end

  def project_phase_fixture(scope, project, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Phase #{System.unique_integer([:positive])}",
        phase_type: :construccion,
        description: "Fase para pruebas automatizadas"
      })

    {:ok, phase} = Projects.create_project_phase(scope, project, attrs)
    phase
  end

  def assignment_fixture(scope, project, user, role \\ :consulta) do
    {:ok, assignment} = Projects.assign_user(scope, project, user, role)
    assignment
  end
end
