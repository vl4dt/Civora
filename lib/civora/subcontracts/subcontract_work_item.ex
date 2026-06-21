defmodule Civora.Subcontracts.SubcontractWorkItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.WorkItem
  alias Civora.Projects.Project
  alias Civora.Subcontracts.Subcontract

  @primary_key false
  schema "subcontract_work_items" do
    belongs_to :project, Project, primary_key: true
    belongs_to :subcontract, Subcontract, primary_key: true
    belongs_to :work_item, WorkItem, primary_key: true

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(link, attrs) do
    link
    |> cast(attrs, [:project_id, :subcontract_id, :work_item_id])
    |> validate_required([:project_id, :subcontract_id, :work_item_id])
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:subcontract_id)
    |> foreign_key_constraint(:work_item_id)
    |> foreign_key_constraint(:subcontract_id,
      name: :subcontract_work_items_subcontract_belongs_to_project
    )
    |> foreign_key_constraint(:work_item_id,
      name: :subcontract_work_items_work_item_belongs_to_project
    )
    |> unique_constraint([:subcontract_id, :work_item_id],
      name: :subcontract_work_items_subcontract_work_item_index
    )
  end
end
