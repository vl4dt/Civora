defmodule Civora.ExecutionFixtures do
  @moduledoc """
  Test helpers for project execution records.
  """

  def work_activity_fixture(scope, project, work_item, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        location_sector: "Sector #{System.unique_integer([:positive])}",
        description: "Actividad de obra para pruebas automatizadas"
      })

    {:ok, activity} = Civora.Execution.create_work_activity(scope, project, work_item, attrs)
    activity
  end

  def executed_progress_fixture(scope, project, activity, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        quantity: "5.5000",
        location_sector: activity.location_sector
      })

    {:ok, entry} = Civora.Execution.create_executed_progress(scope, project, activity, attrs)
    entry
  end

  def quality_control_fixture(scope, project, entry, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        accepted_quantity: Decimal.to_string(entry.quantity, :normal),
        rejection_reason: "",
        non_conformity_originated: false
      })

    {:ok, control} = Civora.Quality.create_quality_control(scope, project, entry, attrs)
    control
  end

  def non_conformity_fixture(scope, project, work_item, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        defect: "Defecto de prueba",
        location_sector: "Sector con no conformidad",
        responsible_name: "Subcontratista de prueba",
        affected_quantity: "1.2500",
        disposition: "Corregir y solicitar reinspeccion"
      })

    {:ok, non_conformity} =
      Civora.Quality.create_non_conformity(scope, project, work_item, attrs)

    non_conformity
  end
end
