defmodule Civora.Subcontracts.SubcontractEstimate do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Projects.Project
  alias Civora.Subcontracts.{Subcontract, SubcontractEstimateLine}

  @statuses [:generated]

  schema "subcontract_estimates" do
    field :status, Ecto.Enum, values: @statuses
    field :amount, :decimal
    field :quality_control_ids, {:array, :integer}, virtual: true, default: []

    belongs_to :project, Project
    belongs_to :subcontract, Subcontract
    has_many :lines, SubcontractEstimateLine

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(estimate, attrs) do
    estimate
    |> cast(attrs, [:project_id, :subcontract_id, :status, :amount, :quality_control_ids])
    |> update_change(:quality_control_ids, &Enum.uniq/1)
    |> validate_required([:project_id, :subcontract_id, :status, :amount])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:subcontract_id)
    |> foreign_key_constraint(:subcontract_id,
      name: :subcontract_estimates_subcontract_belongs_to_project
    )
    |> check_constraint(:status, name: :subcontract_estimates_status_check)
    |> check_constraint(:amount, name: :subcontract_estimates_amount_not_negative)
  end
end
