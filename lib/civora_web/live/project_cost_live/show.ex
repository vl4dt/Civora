defmodule CivoraWeb.ProjectCostLive.Show do
  use CivoraWeb, :live_view

  alias Civora.Projects
  alias Civora.Projects.Project
  alias Civora.Subcontracts

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    with {:ok, project} <- Projects.get_project(socket.assigns.current_scope, project_id),
         {:ok, cost_summary} <-
           Subcontracts.get_project_cost_summary(socket.assigns.current_scope, project) do
      {:ok,
       socket
       |> assign(:page_title, "Costo - #{project.name}")
       |> assign(:project, project)
       |> assign(:cost_summary, cost_summary)}
    else
      {:error, _reason} -> raise Ecto.NoResultsError, queryable: Project
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="max-w-5xl">
        <.link
          navigate={~p"/projects/#{@project}"}
          class="inline-flex items-center gap-2 text-sm text-base-content/65 hover:text-base-content"
        >
          <.icon name="hero-arrow-left" class="size-4" /> {@project.name}
        </.link>

        <div class="mt-6 border-b border-base-300 pb-7">
          <p class="text-sm font-medium text-primary">Control financiero</p>
          <h1 class="mt-1 text-3xl font-semibold">Costo del proyecto</h1>
          <p class="mt-2 max-w-2xl text-sm leading-6 text-base-content/65">
            Vista basica del costo contratado y estimado con base en subcontratos y estimaciones.
          </p>
        </div>

        <section class="grid gap-4 border-b border-base-300 py-7 sm:grid-cols-2 lg:grid-cols-4">
          <div class="border-l-2 border-base-300 pl-4">
            <dt class="text-sm text-base-content/60">Presupuesto aprobado</dt>
            <dd class="mt-1 font-semibold">{approved_budget_label(@cost_summary.approved_budget)}</dd>
          </div>
          <div class="border-l-2 border-primary pl-4">
            <dt class="text-sm text-base-content/60">Monto contratado</dt>
            <dd class="mt-1 font-semibold">{@cost_summary.totals.contracted_amount}</dd>
          </div>
          <div class="border-l-2 border-success pl-4">
            <dt class="text-sm text-base-content/60">Estimado / pagable</dt>
            <dd class="mt-1 font-semibold">
              {@cost_summary.totals.estimated_amount} / {@cost_summary.totals.payable_amount}
            </dd>
          </div>
          <div class="border-l-2 border-warning pl-4">
            <dt class="text-sm text-base-content/60">Saldo basico</dt>
            <dd class="mt-1 font-semibold">{@cost_summary.totals.balance}</dd>
          </div>
        </section>

        <section class="py-7" aria-label="Costo por subcontrato">
          <div class="flex flex-wrap items-end justify-between gap-4">
            <div>
              <p class="text-sm font-medium text-primary">Subcontratos</p>
              <h2 class="mt-1 text-xl font-semibold">Costo acumulado</h2>
            </div>
            <span class="badge badge-outline">{length(@cost_summary.subcontracts)} subcontratos</span>
          </div>

          <div
            :if={@cost_summary.subcontracts == []}
            id="project-cost-empty"
            class="mt-5 grid min-h-40 place-items-center border-y border-base-300 text-center"
          >
            <div>
              <.icon name="hero-banknotes" class="mx-auto size-8 text-base-content/35" />
              <p class="mt-3 font-medium">Sin subcontratos registrados</p>
            </div>
          </div>

          <div :if={@cost_summary.subcontracts != []} class="mt-5 overflow-x-auto">
            <table class="table">
              <thead>
                <tr>
                  <th>Subcontrato</th>
                  <th class="text-right">Contratado</th>
                  <th class="text-right">Pagable acumulado</th>
                  <th class="text-right">Estimado acumulado</th>
                  <th class="text-right">Saldo</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={summary <- @cost_summary.subcontracts}>
                  <td>
                    <.link
                      navigate={~p"/projects/#{@project}/subcontracts/#{summary.subcontract}"}
                      class="font-medium hover:text-primary"
                    >
                      {summary.subcontract.name}
                    </.link>
                    <p class="mt-1 text-xs text-base-content/55">
                      {summary.subcontract.counterparty.name}
                    </p>
                  </td>
                  <td class="text-right">{summary.contracted_amount}</td>
                  <td class="text-right">{summary.payable_amount}</td>
                  <td class="text-right">{summary.estimated_amount}</td>
                  <td class="text-right">{summary.balance}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </section>
    </Layouts.app>
    """
  end

  defp approved_budget_label(nil), do: "Pendiente"

  defp approved_budget_label(%{line_count: line_count}) do
    "Aprobado (#{line_count} partidas)"
  end
end
