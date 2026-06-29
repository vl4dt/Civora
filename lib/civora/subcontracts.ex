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
  alias Civora.Quality.QualityControl
  alias Civora.Repo

  alias Civora.Subcontracts.{
    Counterparty,
    Subcontract,
    SubcontractEstimate,
    SubcontractEstimateLine,
    SubcontractWorkItem
  }

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

  def change_subcontract_estimate(%SubcontractEstimate{} = estimate, attrs \\ %{}) do
    SubcontractEstimate.changeset(estimate, attrs)
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

  def list_subcontract_estimates(
        %Scope{} = scope,
        %Project{} = project,
        %Subcontract{} = subcontract
      ) do
    with true <- Projects.authorized?(scope, project, :view),
         %Subcontract{} <- subcontract_for_project(project, subcontract.id) do
      estimates =
        from(e in SubcontractEstimate,
          where: e.project_id == ^project.id and e.subcontract_id == ^subcontract.id,
          preload: [lines: [:work_item, :quality_control]],
          order_by: [desc: e.inserted_at, desc: e.id]
        )
        |> Repo.all()

      {:ok, estimates}
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
    end
  end

  def list_estimable_payable_progress(
        %Scope{} = scope,
        %Project{} = project,
        %Subcontract{} = subcontract
      ) do
    with true <- Projects.authorized?(scope, project, :view),
         %Subcontract{} = stored_subcontract <- subcontract_for_project(project, subcontract.id) do
      rows =
        stored_subcontract
        |> estimable_payable_progress_query(project)
        |> Repo.all()

      {:ok,
       add_estimate_amounts(
         rows,
         unit_price_for(stored_subcontract.work_items, stored_subcontract)
       )}
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
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

  def create_subcontract_estimate(
        %Scope{user: %User{} = actor} = scope,
        %Project{} = project,
        %Subcontract{} = subcontract,
        attrs
      ) do
    with true <- Projects.authorized?(scope, project, :manage_estimates),
         %Subcontract{} = stored_subcontract <- subcontract_for_project(project, subcontract.id),
         {:ok, selected_ids} <- selected_quality_control_ids(attrs),
         {:ok, rows} <- selected_estimable_rows(project, stored_subcontract, selected_ids) do
      unit_price = unit_price_for(stored_subcontract.work_items, stored_subcontract)
      line_attrs = estimate_line_attrs(project, stored_subcontract, rows, unit_price)
      amount = total_amount(line_attrs)

      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :estimate,
        SubcontractEstimate.changeset(%SubcontractEstimate{}, %{
          project_id: project.id,
          subcontract_id: stored_subcontract.id,
          status: :generated,
          amount: amount
        })
      )
      |> Ecto.Multi.insert_all(:lines, SubcontractEstimateLine, fn %{estimate: estimate} ->
        now = DateTime.utc_now(:second)

        Enum.map(line_attrs, fn attrs ->
          attrs
          |> Map.put(:subcontract_estimate_id, estimate.id)
          |> Map.put(:inserted_at, now)
          |> Map.put(:updated_at, now)
        end)
      end)
      |> Ecto.Multi.insert(:audit_event, fn %{estimate: estimate} ->
        Audit.event_changeset(actor, project, %{
          action: :estimate_created,
          entity_type: "subcontract_estimate",
          entity_id: estimate.id,
          new_state: subcontract_estimate_state(estimate, line_attrs)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{estimate: estimate}} ->
          estimate =
            SubcontractEstimate
            |> Repo.get!(estimate.id)
            |> Repo.preload(lines: [:work_item, :quality_control])

          {:ok, estimate}

        {:error, :estimate, changeset, _changes} ->
          {:error, changeset}

        {:error, _operation, reason, _changes} ->
          {:error, reason}
      end
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
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

  defp subcontract_for_project(%Project{id: project_id}, subcontract_id) do
    from(s in Subcontract,
      where: s.id == ^subcontract_id and s.project_id == ^project_id,
      preload: [:counterparty, :work_items]
    )
    |> Repo.one()
  end

  defp estimable_payable_progress_query(%Subcontract{} = subcontract, %Project{} = project) do
    from(c in QualityControl,
      where: c.project_id == ^project.id and c.accepted_quantity > 0,
      join: link in SubcontractWorkItem,
      on: link.subcontract_id == ^subcontract.id and link.work_item_id == c.work_item_id,
      join: w in assoc(c, :work_item),
      join: e in assoc(c, :executed_progress_entry),
      left_join: line in assoc(c, :subcontract_estimate_line),
      where: is_nil(line.id),
      preload: [work_item: w, executed_progress_entry: e],
      order_by: [asc: w.description, asc: c.inserted_at, asc: c.id]
    )
  end

  defp selected_quality_control_ids(attrs) do
    attrs
    |> fetch_attr(:quality_control_ids)
    |> case do
      ids when is_list(ids) ->
        ids
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.map(&parse_id/1)
        |> then(fn parsed ->
          if Enum.all?(parsed, &match?({:ok, _id}, &1)) do
            ids = parsed |> Enum.map(fn {:ok, id} -> id end) |> Enum.uniq()
            if ids == [], do: {:error, :no_estimable_progress}, else: {:ok, ids}
          else
            {:error, :invalid_quality_control_ids}
          end
        end)

      _other ->
        {:error, :no_estimable_progress}
    end
  end

  defp selected_estimable_rows(project, subcontract, selected_ids) do
    rows =
      subcontract
      |> estimable_payable_progress_query(project)
      |> where([c], c.id in ^selected_ids)
      |> Repo.all()

    if length(rows) == length(selected_ids) do
      {:ok, rows}
    else
      {:error, :invalid_quality_control_ids}
    end
  end

  defp parse_id(id) when is_integer(id), do: {:ok, id}

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {parsed, ""} -> {:ok, parsed}
      _other -> :error
    end
  end

  defp parse_id(_id), do: :error

  defp add_estimate_amounts(rows, unit_price) do
    Enum.map(rows, fn control ->
      amount = line_amount(control.accepted_quantity, unit_price)

      %{
        quality_control: control,
        work_item: control.work_item,
        executed_progress_entry: control.executed_progress_entry,
        quantity: control.accepted_quantity,
        unit_price: unit_price,
        amount: amount
      }
    end)
  end

  defp unit_price_for(work_items, %Subcontract{} = subcontract) do
    total_quantity =
      Enum.reduce(work_items, Decimal.new("0"), fn work_item, total ->
        Decimal.add(total, work_item.quantity)
      end)

    subcontract.current_contract_amount
    |> Decimal.div(total_quantity)
    |> Decimal.round(4)
  end

  defp line_amount(quantity, unit_price) do
    quantity
    |> Decimal.mult(unit_price)
    |> Decimal.round(4)
  end

  defp estimate_line_attrs(project, subcontract, rows, unit_price) do
    Enum.map(rows, fn control ->
      quantity = control.accepted_quantity

      %{
        project_id: project.id,
        subcontract_id: subcontract.id,
        work_item_id: control.work_item_id,
        quality_control_id: control.id,
        executed_progress_entry_id: control.executed_progress_entry_id,
        quantity: quantity,
        unit_price: unit_price,
        amount: line_amount(quantity, unit_price)
      }
    end)
  end

  defp total_amount(line_attrs) do
    Enum.reduce(line_attrs, Decimal.new("0"), fn attrs, total ->
      Decimal.add(total, attrs.amount)
    end)
  end

  defp fetch_attr(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, to_string(key))
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

  defp subcontract_estimate_state(estimate, line_attrs) do
    %{
      "subcontract_id" => estimate.subcontract_id,
      "status" => to_string(estimate.status),
      "amount" => Decimal.to_string(estimate.amount, :normal),
      "lines" =>
        Enum.map(line_attrs, fn attrs ->
          %{
            "work_item_id" => attrs.work_item_id,
            "quality_control_id" => attrs.quality_control_id,
            "executed_progress_entry_id" => attrs.executed_progress_entry_id,
            "quantity" => Decimal.to_string(attrs.quantity, :normal),
            "unit_price" => Decimal.to_string(attrs.unit_price, :normal),
            "amount" => Decimal.to_string(attrs.amount, :normal)
          }
        end)
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
