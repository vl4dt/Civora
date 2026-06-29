defmodule CivoraWeb.SubcontractLive.Show do
  use CivoraWeb, :live_view

  alias Civora.Projects
  alias Civora.Quality
  alias Civora.Subcontracts
  alias Civora.Subcontracts.Subcontract

  @impl true
  def mount(%{"project_id" => project_id, "id" => id}, _session, socket) do
    with {:ok, project} <- Projects.get_project(socket.assigns.current_scope, project_id),
         {:ok, subcontract} <-
           Subcontracts.get_subcontract(socket.assigns.current_scope, project, id),
         {:ok, payable_progress_by_work_item_id} <-
           Quality.list_work_items_payable_progress(
             socket.assigns.current_scope,
             project,
             subcontract.work_items
           ),
         {:ok, estimates} <-
           Subcontracts.list_subcontract_estimates(
             socket.assigns.current_scope,
             project,
             subcontract
           ),
         {:ok, estimable_progress} <-
           Subcontracts.list_estimable_payable_progress(
             socket.assigns.current_scope,
             project,
             subcontract
           ) do
      payable_progress_totals = payable_progress_totals(payable_progress_by_work_item_id)

      {:ok,
       socket
       |> assign(:page_title, subcontract.name)
       |> assign(:project, project)
       |> assign(:subcontract, subcontract)
       |> assign(:payable_progress_by_work_item_id, payable_progress_by_work_item_id)
       |> assign(:payable_progress_totals, payable_progress_totals)
       |> assign(:estimates, estimates)
       |> assign(:estimable_progress, estimable_progress)
       |> assign(:estimable_total, estimable_total(estimable_progress))
       |> assign(
         :can_manage_estimates,
         Projects.authorized?(socket.assigns.current_scope, project, :manage_estimates)
       )
       |> assign_estimate_form()}
    else
      {:error, _reason} -> raise Ecto.NoResultsError, queryable: Subcontract
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="max-w-5xl">
        <.link
          navigate={~p"/projects/#{@project}/subcontracts"}
          class="inline-flex items-center gap-2 text-sm text-base-content/65 hover:text-base-content"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Subcontratos
        </.link>

        <div class="mt-6 border-b border-base-300 pb-7">
          <p class="text-sm font-medium text-primary">{@project.name}</p>

          <h1 class="mt-2 text-3xl font-semibold">{@subcontract.name}</h1>

          <p class="mt-3 text-sm text-base-content/65">{@subcontract.counterparty.name}</p>
        </div>

        <dl class="grid gap-6 border-b border-base-300 py-7 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <dt class="text-sm text-base-content/60">Modalidad</dt>

            <dd class="mt-1 font-semibold">
              {Subcontracts.supply_modality_label(@subcontract.supply_modality)}
            </dd>
          </div>

          <div>
            <dt class="text-sm text-base-content/60">Monto contractual vigente</dt>

            <dd class="mt-1 font-semibold">{@subcontract.current_contract_amount}</dd>
          </div>

          <div>
            <dt class="text-sm text-base-content/60">Anticipo</dt>

            <dd class="mt-1 font-semibold">{@subcontract.advance_percentage}%</dd>
          </div>

          <div>
            <dt class="text-sm text-base-content/60">Retencion / amortizacion</dt>

            <dd class="mt-1 font-semibold">
              {@subcontract.retention_percentage}% / {@subcontract.amortization_percentage}%
            </dd>
          </div>
        </dl>

        <section class="border-b border-base-300 py-7" aria-label="Avance pagable del subcontrato">
          <div class="flex flex-wrap items-end justify-between gap-4">
            <div>
              <p class="text-sm font-medium text-primary">Calidad</p>

              <h2 class="mt-1 text-xl font-semibold">Avance ejecutado vs pagable</h2>
            </div>

            <span class="badge badge-success badge-outline">
              Pagable: {@payable_progress_totals.payable_quantity}
            </span>
          </div>

          <dl class="mt-5 grid gap-4 sm:grid-cols-4">
            <div class="border-l-2 border-base-300 pl-4">
              <dt class="text-sm text-base-content/60">Ejecutado</dt>

              <dd class="mt-1 font-semibold">{@payable_progress_totals.executed_quantity}</dd>
            </div>

            <div class="border-l-2 border-success pl-4">
              <dt class="text-sm text-base-content/60">Pagable</dt>

              <dd class="mt-1 font-semibold">{@payable_progress_totals.payable_quantity}</dd>
            </div>

            <div class="border-l-2 border-warning pl-4">
              <dt class="text-sm text-base-content/60">Rechazado</dt>

              <dd class="mt-1 font-semibold">{@payable_progress_totals.rejected_quantity}</dd>
            </div>

            <div class="border-l-2 border-error pl-4">
              <dt class="text-sm text-base-content/60">No conformidad abierta</dt>

              <dd class="mt-1 font-semibold">
                {@payable_progress_totals.open_non_conformity_quantity}
              </dd>
            </div>
          </dl>
        </section>

        <section class="border-b border-base-300 py-7" aria-label="Estimaciones de subcontrato">
          <div class="flex flex-wrap items-end justify-between gap-4">
            <div>
              <p class="text-sm font-medium text-primary">Costo</p>
              <h2 class="mt-1 text-xl font-semibold">Estimaciones</h2>
            </div>

            <span class="badge badge-outline">
              Pendiente de estimar: {@estimable_total}
            </span>
          </div>

          <.form
            :if={@can_manage_estimates && @estimable_progress != []}
            for={@estimate_form}
            id="subcontract-estimate-form"
            phx-submit="create_estimate"
            class="mt-5"
          >
            <div class="divide-y divide-base-300 border-y border-base-300">
              <label
                :for={row <- @estimable_progress}
                class="grid cursor-pointer gap-3 py-4 sm:grid-cols-[1.5rem_minmax(0,1fr)_auto]"
              >
                <input
                  type="checkbox"
                  name="subcontract_estimate[quality_control_ids][]"
                  value={row.quality_control.id}
                  checked
                  class="checkbox checkbox-primary checkbox-sm mt-1"
                />
                <span>
                  <span class="block font-medium">{row.work_item.description}</span>
                  <span class="mt-1 block text-sm text-base-content/60">
                    {row.executed_progress_entry.location_sector} · Cantidad pagable: {row.quantity} {row.work_item.unit}
                  </span>
                </span>
                <span class="text-sm font-semibold">{row.amount}</span>
              </label>
            </div>

            <input type="hidden" name="subcontract_estimate[quality_control_ids][]" value="" />

            <div class="mt-4 flex flex-wrap items-center justify-between gap-3">
              <p class="text-sm text-base-content/60">
                Solo se muestran cantidades pagables que no pertenecen a una estimacion previa.
              </p>
              <.button class="btn btn-primary" phx-disable-with="Generando...">
                <.icon name="hero-document-plus" class="size-4" /> Generar estimacion
              </.button>
            </div>
          </.form>

          <p
            :if={@can_manage_estimates && @estimable_progress == []}
            class="mt-5 border-y border-base-300 py-5 text-sm text-base-content/60"
          >
            No hay cantidades pagables pendientes de estimar.
          </p>

          <div :if={@estimates != []} class="mt-7 divide-y divide-base-300 border-y border-base-300">
            <article :for={estimate <- @estimates} class="py-5">
              <div class="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <h3 class="font-semibold">Estimacion #{estimate.id}</h3>
                  <p class="mt-1 text-sm text-base-content/60">
                    Estado: {estimate_status_label(estimate.status)} · {length(estimate.lines)} lineas
                  </p>
                </div>
                <span class="font-semibold">{estimate.amount}</span>
              </div>

              <ul class="mt-4 space-y-2 text-sm text-base-content/70">
                <li :for={line <- estimate.lines} class="flex flex-wrap justify-between gap-3">
                  <span>{line.work_item.description} · {line.quantity} {line.work_item.unit}</span>
                  <span>{line.amount}</span>
                </li>
              </ul>
            </article>
          </div>

          <p
            :if={@estimates == []}
            class="mt-5 border-y border-base-300 py-5 text-sm text-base-content/60"
          >
            Aun no hay estimaciones generadas para este subcontrato.
          </p>
        </section>

        <section class="py-7" aria-label="Partidas contratadas">
          <h2 class="text-xl font-semibold">Partidas contratadas</h2>

          <div class="mt-4 divide-y divide-base-300 border-y border-base-300">
            <.link
              :for={item <- @subcontract.work_items}
              navigate={~p"/projects/#{@project}/work-items/#{item}"}
              class="flex flex-wrap items-center justify-between gap-4 py-4 hover:text-primary"
            >
              <% progress = Map.fetch!(@payable_progress_by_work_item_id, item.id) %>
              <span>
                <span class="block font-medium">{item.description}</span>
                <span class="mt-1 block text-sm text-base-content/60">
                  Ejecutado: {progress.executed_quantity} {item.unit} / Pagable: {progress.payable_quantity} {item.unit}
                </span>
              </span>

              <span class="text-sm text-base-content/60">Contratado: {item.quantity} {item.unit}</span>
            </.link>
          </div>
        </section>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("create_estimate", %{"subcontract_estimate" => params}, socket) do
    case Subcontracts.create_subcontract_estimate(
           socket.assigns.current_scope,
           socket.assigns.project,
           socket.assigns.subcontract,
           params
         ) do
      {:ok, _estimate} ->
        {:noreply,
         socket
         |> put_flash(:info, "Estimacion generada correctamente.")
         |> reload_estimates()}

      {:error, :no_estimable_progress} ->
        {:noreply, put_flash(socket, :error, "Selecciona al menos una cantidad pagable.")}

      {:error, :invalid_quality_control_ids} ->
        {:noreply,
         put_flash(socket, :error, "La seleccion incluye cantidades ya estimadas o no pagables.")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "No tienes permiso para generar estimaciones.")}
    end
  end

  defp payable_progress_totals(payable_progress_by_work_item_id) do
    Enum.reduce(
      payable_progress_by_work_item_id,
      %{
        executed_quantity: zero(),
        payable_quantity: zero(),
        rejected_quantity: zero(),
        open_non_conformity_quantity: zero()
      },
      fn {_work_item_id, progress}, totals ->
        %{
          executed_quantity: Decimal.add(totals.executed_quantity, progress.executed_quantity),
          payable_quantity: Decimal.add(totals.payable_quantity, progress.payable_quantity),
          rejected_quantity: Decimal.add(totals.rejected_quantity, progress.rejected_quantity),
          open_non_conformity_quantity:
            Decimal.add(
              totals.open_non_conformity_quantity,
              progress.open_non_conformity_quantity
            )
        }
      end
    )
  end

  defp reload_estimates(socket) do
    {:ok, estimates} =
      Subcontracts.list_subcontract_estimates(
        socket.assigns.current_scope,
        socket.assigns.project,
        socket.assigns.subcontract
      )

    {:ok, estimable_progress} =
      Subcontracts.list_estimable_payable_progress(
        socket.assigns.current_scope,
        socket.assigns.project,
        socket.assigns.subcontract
      )

    socket
    |> assign(:estimates, estimates)
    |> assign(:estimable_progress, estimable_progress)
    |> assign(:estimable_total, estimable_total(estimable_progress))
    |> assign_estimate_form()
  end

  defp assign_estimate_form(socket) do
    assign(
      socket,
      :estimate_form,
      to_form(
        Subcontracts.change_subcontract_estimate(%Civora.Subcontracts.SubcontractEstimate{})
      )
    )
  end

  defp estimable_total(estimable_progress) do
    Enum.reduce(estimable_progress, zero(), fn row, total -> Decimal.add(total, row.amount) end)
  end

  defp estimate_status_label(:generated), do: "Generada"

  defp zero, do: Decimal.new("0.0000")
end
