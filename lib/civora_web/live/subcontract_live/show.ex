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
           ) do
      payable_progress_totals = payable_progress_totals(payable_progress_by_work_item_id)

      {:ok,
       socket
       |> assign(:page_title, subcontract.name)
       |> assign(:project, project)
       |> assign(:subcontract, subcontract)
       |> assign(:payable_progress_by_work_item_id, payable_progress_by_work_item_id)
       |> assign(:payable_progress_totals, payable_progress_totals)}
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

  defp zero, do: Decimal.new("0.0000")
end
