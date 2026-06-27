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
end
