defmodule Civora.Execution.ExecutedProgressEntry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.WorkItem
  alias Civora.Execution.WorkActivity
  alias Civora.Projects.Project

  schema "executed_progress_entries" do
    field :quantity, :decimal
    field :location_sector, :string
    field :payable, :boolean, default: false

    belongs_to :project, Project
    belongs_to :work_item, WorkItem
    belongs_to :work_activity, WorkActivity
    has_one :quality_control, Civora.Quality.QualityControl
    has_many :evidence_attachments, Civora.Evidence.EvidenceAttachment

    timestamps(type: :utc_datetime)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:project_id, :work_item_id, :work_activity_id, :quantity, :location_sector])
    |> put_change(:payable, false)
    |> validate_required([
      :project_id,
      :work_item_id,
      :work_activity_id,
      :quantity,
      :location_sector,
      :payable
    ])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_length(:location_sector, min: 2, max: 160)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:work_item_id)
    |> foreign_key_constraint(:work_activity_id)
    |> foreign_key_constraint(:work_item_id,
      name: :executed_progress_entries_work_item_belongs_to_project
    )
    |> foreign_key_constraint(:work_activity_id,
      name: :executed_progress_entries_activity_belongs_to_work_item
    )
    |> check_constraint(:quantity, name: :executed_progress_entries_quantity_positive)
    |> check_constraint(:location_sector,
      name: :executed_progress_entries_location_sector_length
    )
  end

  def payable_changeset(entry, payable) when is_boolean(payable) do
    change(entry, payable: payable)
  end
end
