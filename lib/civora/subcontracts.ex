defmodule Civora.Subcontracts do
  @moduledoc """
  Global counterpart identities used by project-specific subcontracts.
  """

  import Ecto.Query, warn: false

  alias Civora.Accounts.{Scope, User}
  alias Civora.Repo
  alias Civora.Subcontracts.Counterparty

  def available_counterparty_roles, do: Counterparty.roles()

  def counterparty_role_label(:proveedor), do: "Proveedor"
  def counterparty_role_label(:subcontratista), do: "Subcontratista"
  def counterparty_role_label(:ambos), do: "Proveedor y subcontratista"

  def change_counterparty(%Counterparty{} = counterparty, attrs \\ %{}) do
    Counterparty.changeset(counterparty, attrs)
  end

  def list_counterparties(%Scope{user: %User{}}) do
    Repo.all(from(c in Counterparty, order_by: [asc: c.name, asc: c.id]))
  end

  def get_counterparty(%Scope{user: %User{}}, id) do
    case Repo.get(Counterparty, id) do
      nil -> {:error, :not_found}
      counterparty -> {:ok, counterparty}
    end
  end

  def create_counterparty(%Scope{user: %User{}}, attrs) do
    %Counterparty{}
    |> Counterparty.changeset(attrs)
    |> Repo.insert()
  end
end
