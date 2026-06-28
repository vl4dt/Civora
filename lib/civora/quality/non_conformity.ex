defmodule Civora.Quality.NonConformity do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.WorkItem
  alias Civora.Execution.ExecutedProgressEntry
  alias Civora.Projects.Project
  alias Civora.Quality.QualityControl

  @statuses [:open, :closed]

  schema "non_conformities" do
    field :defect, :string
    field :location_sector, :string
    field :responsible_name, :string
    field :status, Ecto.Enum, values: @statuses, default: :open
    field :affected_quantity, :decimal
    field :disposition, :string
    field :due_on, :date
    field :closure_notes, :string
    field :closed_at, :utc_datetime

    belongs_to :project, Project
    belongs_to :work_item, WorkItem
    belongs_to :quality_control, QualityControl
    belongs_to :executed_progress_entry, ExecutedProgressEntry

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(non_conformity, attrs) do
    non_conformity
    |> cast(attrs, [
      :project_id,
      :work_item_id,
      :quality_control_id,
      :executed_progress_entry_id,
      :defect,
      :location_sector,
      :responsible_name,
      :status,
      :affected_quantity,
      :disposition,
      :due_on,
      :closure_notes,
      :closed_at
    ])
    |> put_new_status()
    |> validate_required([
      :project_id,
      :work_item_id,
      :defect,
      :location_sector,
      :responsible_name,
      :status,
      :affected_quantity
    ])
    |> validate_number(:affected_quantity, greater_than: 0)
    |> validate_length(:defect, min: 2, max: 2_000)
    |> validate_length(:location_sector, min: 2, max: 160)
    |> validate_length(:responsible_name, min: 2, max: 160)
    |> validate_length(:disposition, max: 1_000)
    |> validate_length(:closure_notes, max: 1_000)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:work_item_id)
    |> foreign_key_constraint(:quality_control_id)
    |> foreign_key_constraint(:executed_progress_entry_id)
    |> foreign_key_constraint(:work_item_id,
      name: :non_conformities_work_item_belongs_to_project
    )
    |> foreign_key_constraint(:quality_control_id,
      name: :non_conformities_quality_control_belongs_to_work_item
    )
    |> foreign_key_constraint(:executed_progress_entry_id,
      name: :non_conformities_progress_belongs_to_work_item
    )
    |> unique_constraint(:quality_control_id)
    |> check_constraint(:affected_quantity,
      name: :non_conformities_affected_quantity_positive
    )
    |> check_constraint(:defect, name: :non_conformities_defect_length)
    |> check_constraint(:location_sector, name: :non_conformities_location_sector_length)
    |> check_constraint(:responsible_name, name: :non_conformities_responsible_name_length)
    |> check_constraint(:disposition, name: :non_conformities_disposition_length)
    |> check_constraint(:closure_notes, name: :non_conformities_closure_notes_length)
  end

  def close_changeset(non_conformity, attrs) do
    non_conformity
    |> cast(attrs, [:closure_notes, :closed_at])
    |> put_change(:status, :closed)
    |> validate_required([:closure_notes, :closed_at])
    |> validate_length(:closure_notes, min: 2, max: 1_000)
    |> check_constraint(:closure_notes, name: :non_conformities_closure_notes_length)
  end

  defp put_new_status(changeset) do
    case get_field(changeset, :status) do
      nil -> put_change(changeset, :status, :open)
      _status -> changeset
    end
  end
end
