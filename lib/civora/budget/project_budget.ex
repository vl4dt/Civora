defmodule Civora.Budget.ProjectBudget do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Accounts.User
  alias Civora.Budget.ProjectBudgetLine
  alias Civora.Projects.Project

  @statuses [:draft, :approved]

  schema "project_budgets" do
    field :status, Ecto.Enum, values: @statuses, default: :draft
    field :approved_at, :utc_datetime

    belongs_to :project, Project
    belongs_to :approved_by, User
    has_many :lines, ProjectBudgetLine

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def create_changeset(budget, attrs) do
    budget
    |> cast(attrs, [:project_id])
    |> validate_required([:project_id])
    |> foreign_key_constraint(:project_id)
    |> unique_constraint(:project_id)
  end

  def approval_changeset(budget, actor_id, approved_at) do
    budget
    |> change(status: :approved, approved_by_id: actor_id, approved_at: approved_at)
    |> check_constraint(:status, name: :project_budgets_status_check)
    |> check_constraint(:status, name: :project_budgets_approval_fields_check)
  end
end
