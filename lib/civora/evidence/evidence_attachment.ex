defmodule Civora.Evidence.EvidenceAttachment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Accounts.User
  alias Civora.Budget.WorkItem
  alias Civora.Execution.ExecutedProgressEntry
  alias Civora.Projects.Project
  alias Civora.Quality.{NonConformity, QualityControl}

  @statuses [:valid, :invalidated]

  schema "evidence_attachments" do
    field :object_key, :string
    field :original_filename, :string
    field :content_type, :string
    field :byte_size, :integer
    field :status, Ecto.Enum, values: @statuses, default: :valid
    field :invalidated_at, :utc_datetime
    field :invalidation_reason, :string

    belongs_to :project, Project
    belongs_to :work_item, WorkItem
    belongs_to :executed_progress_entry, ExecutedProgressEntry
    belongs_to :quality_control, QualityControl
    belongs_to :non_conformity, NonConformity
    belongs_to :uploaded_by, User
    belongs_to :invalidated_by, User

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [
      :project_id,
      :work_item_id,
      :executed_progress_entry_id,
      :quality_control_id,
      :non_conformity_id,
      :object_key,
      :original_filename,
      :content_type,
      :byte_size,
      :status,
      :uploaded_by_id,
      :invalidated_by_id,
      :invalidated_at,
      :invalidation_reason
    ])
    |> put_new_status()
    |> validate_required([
      :project_id,
      :work_item_id,
      :object_key,
      :original_filename,
      :content_type,
      :byte_size,
      :status,
      :uploaded_by_id
    ])
    |> validate_number(:byte_size, greater_than: 0)
    |> validate_length(:object_key, min: 1, max: 500)
    |> validate_length(:original_filename, min: 1, max: 255)
    |> validate_length(:content_type, min: 1, max: 255)
    |> validate_length(:invalidation_reason, max: 1_000)
    |> validate_one_parent()
    |> validate_invalidation_state()
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:work_item_id)
    |> foreign_key_constraint(:executed_progress_entry_id)
    |> foreign_key_constraint(:quality_control_id)
    |> foreign_key_constraint(:non_conformity_id)
    |> foreign_key_constraint(:uploaded_by_id)
    |> foreign_key_constraint(:invalidated_by_id)
    |> foreign_key_constraint(:work_item_id,
      name: :evidence_attachments_work_item_belongs_to_project
    )
    |> foreign_key_constraint(:executed_progress_entry_id,
      name: :evidence_attachments_progress_belongs_to_work_item
    )
    |> foreign_key_constraint(:quality_control_id,
      name: :evidence_attachments_quality_belongs_to_work_item
    )
    |> foreign_key_constraint(:non_conformity_id,
      name: :evidence_attachments_non_conformity_belongs_to_work_item
    )
    |> unique_constraint(:object_key)
    |> check_constraint(:executed_progress_entry_id,
      name: :evidence_attachments_one_parent_check
    )
    |> check_constraint(:status, name: :evidence_attachments_status_check)
    |> check_constraint(:byte_size, name: :evidence_attachments_byte_size_positive)
    |> check_constraint(:original_filename, name: :evidence_attachments_filename_length)
    |> check_constraint(:content_type, name: :evidence_attachments_content_type_length)
    |> check_constraint(:status, name: :evidence_attachments_invalidation_state_check)
  end

  def invalidate_changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:invalidated_by_id, :invalidated_at, :invalidation_reason])
    |> put_change(:status, :invalidated)
    |> validate_required([:invalidated_by_id, :invalidated_at, :invalidation_reason])
    |> validate_length(:invalidation_reason, min: 2, max: 1_000)
    |> foreign_key_constraint(:invalidated_by_id)
    |> check_constraint(:status, name: :evidence_attachments_invalidation_state_check)
  end

  defp put_new_status(changeset) do
    case get_field(changeset, :status) do
      nil -> put_change(changeset, :status, :valid)
      _status -> changeset
    end
  end

  defp validate_one_parent(changeset) do
    parent_count =
      [
        get_field(changeset, :executed_progress_entry_id),
        get_field(changeset, :quality_control_id),
        get_field(changeset, :non_conformity_id)
      ]
      |> Enum.reject(&is_nil/1)
      |> length()

    if parent_count == 1 do
      changeset
    else
      add_error(changeset, :base, "must be linked to exactly one evidence parent")
    end
  end

  defp validate_invalidation_state(changeset) do
    case get_field(changeset, :status) do
      :valid ->
        changeset

      :invalidated ->
        validate_required(changeset, [
          :invalidated_by_id,
          :invalidated_at,
          :invalidation_reason
        ])
    end
  end
end
