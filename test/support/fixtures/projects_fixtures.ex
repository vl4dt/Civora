defmodule Civora.ProjectsFixtures do
  @moduledoc """
  Test helpers for project identities and project assignments.
  """

  alias Civora.Projects

  def unique_project_name, do: "Project #{System.unique_integer([:positive])}"

  def project_fixture(scope, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{name: unique_project_name()})
    {:ok, project} = Projects.create_project(scope, attrs)
    project
  end

  def assignment_fixture(scope, project, user, role \\ :consulta) do
    {:ok, assignment} = Projects.assign_user(scope, project, user, role)
    assignment
  end
end
