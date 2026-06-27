defmodule Civora.Subcontracts do
  @moduledoc """
  Counterpart identities and project-scoped subcontract agreements.
  """

  import Ecto.Query, warn: false

  alias Civora.Accounts.{Scope, User}
  alias Civora.Audit
  alias Civora.Budget.WorkItem
  alias Civora.Projects
  alias Civora.Projects.Project
  alias Civora.Repo
  alias Civora.Subcontracts.{Counterparty, Subcontract, SubcontractWorkItem}

  def available_counterparty_roles, do: Counterparty.roles()

  def counterparty_role_label(:proveedor), do: "Proveedor"
  def counterparty_role_label(:subcontratista), do: "Subcontratista"
  def counterparty_role_label(:ambos), do: "Proveedor y subcontratista"

  def available_supply_modalities, do: Subcontract.supply_modalities()

  def supply_modality_label(:solo_mano_obra), do: "Solo mano de obra"
  def supply_modality_label(:mano_obra_materiales), do: "Mano de obra con materiales"
  def supply_modality_label(:mixta), do: "Mixta"

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

  def change_subcontract(%Subcontract{} = subcontract, attrs \\ %{}) do
    Subcontract.changeset(subcontract, attrs)
  end

  def list_subcontractor_counterparties(%Scope{user: %User{}}) do
    Repo.all(
      from(c in Counterparty,
        where: c.role in [:subcontratista, :ambos],
        order_by: [asc: c.name, asc: c.id]
      )
    )
  end

  def list_subcontracts(%Scope{} = scope, %Project{} = project) do
    with true <- Projects.authorized?(scope, project, :view) do
      subcontracts =
        from(s in Subcontract,
          where: s.project_id == ^project.id,
          preload: [:counterparty, :work_items],
          order_by: [asc: s.name, asc: s.id]
        )
        |> Repo.all()

      {:ok, subcontracts}
    else
      false -> {:error, :unauthorized}
    end
  end

  def get_subcontract(%Scope{} = scope, %Project{} = project, id) do
    with true <- Projects.authorized?(scope, project, :view) do
      from(s in Subcontract,
        where: s.id == ^id and s.project_id == ^project.id,
        preload: [:counterparty, :work_items]
      )
      |> Repo.one()
      |> case do
        nil -> {:error, :not_found}
        subcontract -> {:ok, subcontract}
      end
    else
      false -> {:error, :unauthorized}
    end
  end

  def create_subcontract(
        %Scope{user: %User{} = actor} = scope,
        %Project{} = project,
        attrs
      ) do
    with true <- Projects.authorized?(scope, project, :manage_subcontracts) do
      attrs = put_project_id(attrs, project.id)
      changeset = Subcontract.changeset(%Subcontract{}, attrs)

      Ecto.Multi.new()
      |> Ecto.Multi.run(:validated_inputs, fn repo, _changes ->
        validate_subcontract_inputs(repo, changeset, project.id)
      end)
      |> Ecto.Multi.insert(:subcontract, changeset)
      |> Ecto.Multi.insert_all(
        :work_item_links,
        SubcontractWorkItem,
        &work_item_link_rows(&1, project.id)
      )
      |> Ecto.Multi.insert(:audit_event, fn %{
                                              subcontract: subcontract,
                                              validated_inputs: %{work_items: work_items}
                                            } ->
        Audit.event_changeset(actor, project, %{
          action: :subcontract_created,
          entity_type: "subcontract",
          entity_id: subcontract.id,
          new_state: subcontract_state(subcontract, work_items)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{subcontract: subcontract}} ->
          {:ok, Repo.preload(subcontract, [:counterparty, :work_items])}

        {:error, operation, %Ecto.Changeset{} = failed_changeset, _changes}
        when operation in [:validated_inputs, :subcontract] ->
          {:error, failed_changeset}

        {:error, _operation, reason, _changes} ->
          {:error, reason}
      end
    else
      false -> {:error, :unauthorized}
    end
  end

  defp validate_subcontract_inputs(
         _repo,
         %Ecto.Changeset{valid?: false} = changeset,
         _project_id
       ),
       do: {:error, changeset}

  defp validate_subcontract_inputs(repo, changeset, project_id) do
    counterparty_id = Ecto.Changeset.get_field(changeset, :counterparty_id)
    work_item_ids = Ecto.Changeset.get_field(changeset, :work_item_ids)
    counterparty = repo.get(Counterparty, counterparty_id)

    work_items =
      repo.all(
        from(w in WorkItem,
          where: w.project_id == ^project_id and w.id in ^work_item_ids,
          order_by: [asc: w.id]
        )
      )

    changeset =
      changeset
      |> validate_counterparty(counterparty)
      |> validate_work_items(work_items, work_item_ids)

    if changeset.valid? do
      {:ok, %{counterparty: counterparty, work_items: work_items}}
    else
      {:error, changeset}
    end
  end

  defp validate_counterparty(changeset, %Counterparty{role: role})
       when role in [:subcontratista, :ambos],
       do: changeset

  defp validate_counterparty(changeset, _counterparty) do
    Ecto.Changeset.add_error(
      changeset,
      :counterparty_id,
      "must be an eligible subcontractor counterparty"
    )
  end

  defp validate_work_items(changeset, work_items, work_item_ids) do
    if length(work_items) == length(work_item_ids) do
      changeset
    else
      Ecto.Changeset.add_error(changeset, :work_item_ids, "must belong to the project")
    end
  end

  defp put_project_id(attrs, project_id) do
    if Enum.any?(Map.keys(attrs), &is_binary/1) do
      Map.put(attrs, "project_id", project_id)
    else
      Map.put(attrs, :project_id, project_id)
    end
  end

  defp subcontract_state(subcontract, work_items) do
    %{
      "name" => subcontract.name,
      "counterparty_id" => subcontract.counterparty_id,
      "supply_modality" => to_string(subcontract.supply_modality),
      "current_contract_amount" => Decimal.to_string(subcontract.current_contract_amount),
      "advance_percentage" => Decimal.to_string(subcontract.advance_percentage),
      "retention_percentage" => Decimal.to_string(subcontract.retention_percentage),
      "amortization_percentage" => Decimal.to_string(subcontract.amortization_percentage),
      "work_item_ids" => Enum.map(work_items, & &1.id)
    }
  end

  defp work_item_link_rows(
         %{subcontract: subcontract, validated_inputs: %{work_items: work_items}},
         project_id
       ) do
    now = DateTime.utc_now(:second)

    Enum.map(work_items, fn item ->
      %{
        project_id: project_id,
        subcontract_id: subcontract.id,
        work_item_id: item.id,
        inserted_at: now
      }
    end)
  end
end
