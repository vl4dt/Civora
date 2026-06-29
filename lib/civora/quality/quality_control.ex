defmodule Civora.Quality.QualityControl do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.WorkItem
  alias Civora.Execution.ExecutedProgressEntry
  alias Civora.Projects.Project

  @statuses [:accepted, :partially_accepted, :rejected]

  schema "quality_controls" do
    field :status, Ecto.Enum, values: @statuses
    field :accepted_quantity, :decimal
    field :rejected_quantity, :decimal
    field :rejection_reason, :string
    field :non_conformity_originated, :boolean, default: false

    belongs_to :project, Project
    belongs_to :work_item, WorkItem
    belongs_to :executed_progress_entry, ExecutedProgressEntry
    has_one :non_conformity, Civora.Quality.NonConformity
    has_one :subcontract_estimate_line, Civora.Subcontracts.SubcontractEstimateLine

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(control, attrs) do
    control
    |> cast(attrs, [
      :project_id,
      :work_item_id,
      :executed_progress_entry_id,
      :status,
      :accepted_quantity,
      :rejected_quantity,
      :rejection_reason,
      :non_conformity_originated
    ])
    |> validate_required([
      :project_id,
      :work_item_id,
      :executed_progress_entry_id,
      :status,
      :accepted_quantity,
      :rejected_quantity,
      :non_conformity_originated
    ])
    |> validate_number(:accepted_quantity, greater_than_or_equal_to: 0)
    |> validate_number(:rejected_quantity, greater_than_or_equal_to: 0)
    |> validate_length(:rejection_reason, max: 1_000)
    |> validate_rejection_reason()
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:work_item_id)
    |> foreign_key_constraint(:executed_progress_entry_id)
    |> foreign_key_constraint(:work_item_id, name: :quality_controls_work_item_belongs_to_project)
    |> foreign_key_constraint(:executed_progress_entry_id,
      name: :quality_controls_progress_belongs_to_work_item
    )
    |> unique_constraint(:executed_progress_entry_id)
    |> check_constraint(:accepted_quantity,
      name: :quality_controls_accepted_quantity_not_negative
    )
    |> check_constraint(:rejected_quantity,
      name: :quality_controls_rejected_quantity_not_negative
    )
    |> check_constraint(:rejection_reason, name: :quality_controls_rejection_reason_length)
  end

  defp validate_rejection_reason(changeset) do
    rejected_quantity = get_field(changeset, :rejected_quantity)

    if rejected_quantity && Decimal.gt?(rejected_quantity, Decimal.new("0")) do
      validate_required(changeset, [:rejection_reason])
    else
      changeset
    end
  end
end
