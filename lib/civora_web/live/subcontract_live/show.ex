defmodule CivoraWeb.SubcontractLive.Show do
  use CivoraWeb, :live_view

  alias Civora.Projects
  alias Civora.Subcontracts
  alias Civora.Subcontracts.Subcontract

  @impl true
  def mount(%{"project_id" => project_id, "id" => id}, _session, socket) do
    with {:ok, project} <- Projects.get_project(socket.assigns.current_scope, project_id),
         {:ok, subcontract} <-
           Subcontracts.get_subcontract(socket.assigns.current_scope, project, id) do
      {:ok,
       socket
       |> assign(:page_title, subcontract.name)
       |> assign(:project, project)
       |> assign(:subcontract, subcontract)}
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

        <section class="py-7" aria-label="Partidas contratadas">
          <h2 class="text-xl font-semibold">Partidas contratadas</h2>
          <div class="mt-4 divide-y divide-base-300 border-y border-base-300">
            <.link
              :for={item <- @subcontract.work_items}
              navigate={~p"/projects/#{@project}/work-items/#{item}"}
              class="flex items-center justify-between gap-4 py-4 hover:text-primary"
            >
              <span>{item.description}</span>
              <span class="text-sm text-base-content/60">{item.quantity} {item.unit}</span>
            </.link>
          </div>
        </section>
      </section>
    </Layouts.app>
    """
  end
end
