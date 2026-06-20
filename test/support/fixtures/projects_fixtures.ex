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

  def work_item_fixture(scope, project, phase, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        project_phase_id: phase.id,
        unit: "m2",
        quantity: "25.5000",
        description: "Partida #{System.unique_integer([:positive])}"
      })

    {:ok, item} = Civora.Budget.create_work_item(scope, project, attrs)
    item
  end

  def performance_sheet_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Performance sheet #{System.unique_integer([:positive])}",
        description: "Ficha reutilizable para pruebas automatizadas",
        unit: "m2",
        productivity: "18.5000",
        waste_percentage: "5.0000",
        resources: [
          %{category: :material, name: "Bloque", unit: "unidad", quantity: "12.5"},
          %{category: :labor, name: "Albanil", unit: "jornal", quantity: "0.75"}
        ]
      })

    {:ok, sheet} = Civora.Budget.create_performance_sheet(scope, attrs)
    sheet
  end

  def budgeted_performance_sheet_fixture(scope, project, work_item, source \\ nil) do
    source = source || performance_sheet_fixture(scope)

    {:ok, sheet} =
      Civora.Budget.create_budgeted_performance_sheet(scope, project, work_item, source.id)

    sheet
  end
end
