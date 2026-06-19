defmodule Civora.Budget.PerformanceSheetResource do
  use Ecto.Schema
  import Ecto.Changeset

  alias Civora.Budget.PerformanceSheet

  @categories [:material, :labor]

  schema "performance_sheet_resources" do
    field :category, Ecto.Enum, values: @categories
    field :name, :string
    field :unit, :string
    field :quantity, :decimal

    belongs_to :performance_sheet, PerformanceSheet

    timestamps(type: :utc_datetime)
  end

  def categories, do: @categories

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:category, :name, :unit, :quantity])
    |> validate_required([:category, :name, :unit, :quantity])
    |> validate_length(:name, min: 2, max: 160)
    |> validate_length(:unit, min: 1, max: 40)
    |> validate_number(:quantity, greater_than: 0)
    |> check_constraint(:category, name: :performance_sheet_resources_category_check)
    |> check_constraint(:quantity, name: :performance_sheet_resources_quantity_positive)
    |> ignore_blank_resource(attrs)
  end

  defp ignore_blank_resource(changeset, attrs) do
    values =
      Enum.map(
        ~w(category name unit quantity),
        &(attrs[to_string(&1)] || attrs[String.to_atom(&1)])
      )

    if Enum.all?(values, &(&1 in [nil, ""])), do: %{changeset | action: :ignore}, else: changeset
  end
end
