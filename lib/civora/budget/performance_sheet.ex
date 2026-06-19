defmodule Civora.Budget.PerformanceSheet do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.PerformanceSheetResource

  schema "performance_sheets" do
    field :name, :string
    field :description, :string
    field :unit, :string
    field :productivity, :decimal
    field :waste_percentage, :decimal

    has_many :resources, PerformanceSheetResource, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def changeset(sheet, attrs) do
    sheet
    |> cast(attrs, [:name, :description, :unit, :productivity, :waste_percentage])
    |> validate_required([:name, :description, :unit])
    |> validate_length(:name, min: 2, max: 160)
    |> validate_length(:description, min: 2, max: 2_000)
    |> validate_length(:unit, min: 1, max: 40)
    |> validate_number(:productivity, greater_than: 0)
    |> validate_number(:waste_percentage, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> unique_constraint(:name)
    |> check_constraint(:productivity, name: :performance_sheets_productivity_positive)
    |> check_constraint(:waste_percentage, name: :performance_sheets_waste_percentage_range)
    |> cast_assoc(:resources, with: &PerformanceSheetResource.changeset/2, required: true)
  end
end
