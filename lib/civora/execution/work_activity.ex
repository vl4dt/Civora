defmodule Civora.Execution.WorkActivity do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.WorkItem
  alias Civora.Projects.Project

  schema "work_activities" do
    field :location_sector, :string
    field :description, :string

    belongs_to :project, Project
    belongs_to :work_item, WorkItem

    timestamps(type: :utc_datetime)
  end

  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:project_id, :work_item_id, :location_sector, :description])
    |> validate_required([:project_id, :work_item_id, :location_sector, :description])
    |> validate_length(:location_sector, min: 2, max: 160)
    |> validate_length(:description, min: 2, max: 2_000)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:work_item_id)
    |> foreign_key_constraint(:work_item_id, name: :work_activities_work_item_belongs_to_project)
    |> check_constraint(:location_sector, name: :work_activities_location_sector_length)
    |> check_constraint(:description, name: :work_activities_description_length)
  end
end
