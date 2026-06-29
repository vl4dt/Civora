defmodule Civora.Subcontracts.SubcontractEstimateLine do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.WorkItem
  alias Civora.Execution.ExecutedProgressEntry
  alias Civora.Projects.Project
  alias Civora.Quality.QualityControl
  alias Civora.Subcontracts.{Subcontract, SubcontractEstimate}

  schema "subcontract_estimate_lines" do
    field :quantity, :decimal
    field :unit_price, :decimal
    field :amount, :decimal

    belongs_to :project, Project
    belongs_to :subcontract_estimate, SubcontractEstimate
    belongs_to :subcontract, Subcontract
    belongs_to :work_item, WorkItem
    belongs_to :quality_control, QualityControl
    belongs_to :executed_progress_entry, ExecutedProgressEntry

    timestamps(type: :utc_datetime)
  end

  def changeset(line, attrs) do
    line
    |> cast(attrs, [
      :project_id,
      :subcontract_estimate_id,
      :subcontract_id,
      :work_item_id,
      :quality_control_id,
      :executed_progress_entry_id,
      :quantity,
      :unit_price,
      :amount
    ])
    |> validate_required([
      :project_id,
      :subcontract_estimate_id,
      :subcontract_id,
      :work_item_id,
      :quality_control_id,
      :executed_progress_entry_id,
      :quantity,
      :unit_price,
      :amount
    ])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:unit_price, greater_than: 0)
    |> validate_number(:amount, greater_than: 0)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:subcontract_estimate_id)
    |> foreign_key_constraint(:subcontract_id)
    |> foreign_key_constraint(:work_item_id)
    |> foreign_key_constraint(:quality_control_id)
    |> foreign_key_constraint(:executed_progress_entry_id)
    |> foreign_key_constraint(:subcontract_estimate_id,
      name: :subcontract_estimate_lines_estimate_belongs_to_project
    )
    |> foreign_key_constraint(:subcontract_id,
      name: :subcontract_estimate_lines_subcontract_belongs_to_project
    )
    |> foreign_key_constraint(:work_item_id,
      name: :subcontract_estimate_lines_work_item_belongs_to_subcontract
    )
    |> foreign_key_constraint(:quality_control_id,
      name: :subcontract_estimate_lines_quality_belongs_to_work_item
    )
    |> unique_constraint(:quality_control_id)
    |> check_constraint(:quantity, name: :subcontract_estimate_lines_quantity_positive)
    |> check_constraint(:unit_price, name: :subcontract_estimate_lines_unit_price_positive)
    |> check_constraint(:amount, name: :subcontract_estimate_lines_amount_positive)
  end
end
