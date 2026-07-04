defmodule CivoraWeb.ProjectReportLive.Show do
  use CivoraWeb, :live_view

  alias Civora.Projects
  alias Civora.Projects.Project
  alias Civora.Reports

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    with {:ok, project} <- Projects.get_project(socket.assigns.current_scope, project_id),
         {:ok, report} <-
           Reports.get_internal_project_report(socket.assigns.current_scope, project) do
      {:ok,
       socket
       |> assign(:page_title, "Reporte interno - #{project.name}")
       |> assign(:project, project)
       |> assign(:report, report)}
    else
      {:error, _reason} -> raise Ecto.NoResultsError, queryable: Project
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="max-w-6xl">
        <.link
          navigate={~p"/projects/#{@project}"}
          class="inline-flex items-center gap-2 text-sm text-base-content/65 hover:text-base-content"
        >
          <.icon name="hero-arrow-left" class="size-4" /> {@project.name}
        </.link>

        <div class="mt-6 border-b border-base-300 pb-7">
          <p class="text-sm font-medium text-primary">MVP</p>
          <h1 class="mt-1 text-3xl font-semibold">Reporte interno</h1>
          <p class="mt-2 max-w-3xl text-sm leading-6 text-base-content/65">
            Resumen operativo interno con presupuesto, avance, calidad, estimaciones y costo acumulado.
          </p>
        </div>

        <section class="grid gap-4 border-b border-base-300 py-7 sm:grid-cols-2 lg:grid-cols-4">
          <div class="border-l-2 border-base-300 pl-4">
            <dt class="text-sm text-base-content/60">Partidas presupuestadas</dt>
            <dd class="mt-1 font-semibold">{length(@report.budget_lines)}</dd>
          </div>
          <div class="border-l-2 border-success pl-4">
            <dt class="text-sm text-base-content/60">Avance estimado / pagable</dt>
            <dd class="mt-1 font-semibold">
              {@report.cost_summary.totals.estimated_amount} / {@report.cost_summary.totals.payable_amount}
            </dd>
          </div>
          <div class="border-l-2 border-error pl-4">
            <dt class="text-sm text-base-content/60">No conformidades abiertas</dt>
            <dd class="mt-1 font-semibold">{length(@report.open_non_conformities)}</dd>
          </div>
          <div class="border-l-2 border-warning pl-4">
            <dt class="text-sm text-base-content/60">Costo acumulado</dt>
            <dd class="mt-1 font-semibold">{@report.cost_summary.totals.estimated_amount}</dd>
          </div>
        </section>

        <section class="border-b border-base-300 py-7" aria-label="Partidas presupuestadas">
          <div class="flex flex-wrap items-end justify-between gap-4">
            <div>
              <p class="text-sm font-medium text-primary">Presupuesto</p>
              <h2 class="mt-1 text-xl font-semibold">Partidas presupuestadas</h2>
            </div>
            <span class="badge badge-outline">{budget_status_label(@report.budget)}</span>
          </div>

          <div
            :if={@report.budget_lines == []}
            id="internal-report-budget-empty"
            class="mt-5 grid min-h-32 place-items-center border-y border-base-300 text-center"
          >
            <div>
              <.icon name="hero-banknotes" class="mx-auto size-8 text-base-content/35" />
              <p class="mt-3 font-medium">Sin presupuesto aprobado</p>
            </div>
          </div>

          <div :if={@report.budget_lines != []} class="mt-5 overflow-x-auto">
            <table class="table">
              <thead>
                <tr>
                  <th>Fase</th>
                  <th>Partida</th>
                  <th class="text-right">Cantidad</th>
                  <th>Ficha</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={line <- @report.budget_lines}>
                  <td>{line.phase_name}</td>
                  <td class="font-medium">{line.description}</td>
                  <td class="text-right">{line.quantity} {line.unit}</td>
                  <td>{line.sheet_name || "Sin ficha"}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="border-b border-base-300 py-7" aria-label="Avance ejecutado y pagable">
          <p class="text-sm font-medium text-primary">Avance</p>
          <h2 class="mt-1 text-xl font-semibold">Ejecutado y pagable</h2>

          <div class="mt-5 overflow-x-auto">
            <table class="table">
              <thead>
                <tr>
                  <th>Partida</th>
                  <th class="text-right">Ejecutado</th>
                  <th class="text-right">Pagable</th>
                  <th class="text-right">Rechazado</th>
                  <th class="text-right">NC abierta</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={row <- @report.work_item_progress}>
                  <td>
                    <.link
                      navigate={~p"/projects/#{@project}/work-items/#{row.work_item}"}
                      class="font-medium hover:text-primary"
                    >
                      {row.work_item.description}
                    </.link>
                    <p :if={row.budget_line} class="mt-1 text-xs text-base-content/55">
                      Presupuestado: {row.budget_line.quantity} {row.budget_line.unit}
                    </p>
                  </td>
                  <td class="text-right">{row.progress.executed_quantity} {row.work_item.unit}</td>
                  <td class="text-right">{row.progress.payable_quantity} {row.work_item.unit}</td>
                  <td class="text-right">{row.progress.rejected_quantity} {row.work_item.unit}</td>
                  <td class="text-right">
                    {row.progress.open_non_conformity_quantity} {row.work_item.unit}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="border-b border-base-300 py-7" aria-label="No conformidades abiertas">
          <div class="flex flex-wrap items-end justify-between gap-4">
            <div>
              <p class="text-sm font-medium text-primary">Calidad</p>
              <h2 class="mt-1 text-xl font-semibold">No conformidades abiertas</h2>
            </div>
            <span class="badge badge-outline">{length(@report.open_non_conformities)} abiertas</span>
          </div>

          <div
            :if={@report.open_non_conformities == []}
            id="internal-report-non-conformities-empty"
            class="mt-5 grid min-h-32 place-items-center border-y border-base-300 text-center"
          >
            <div>
              <.icon name="hero-check-circle" class="mx-auto size-8 text-base-content/35" />
              <p class="mt-3 font-medium">Sin no conformidades abiertas</p>
            </div>
          </div>

          <div :if={@report.open_non_conformities != []} class="mt-5 overflow-x-auto">
            <table class="table">
              <thead>
                <tr>
                  <th>Partida</th>
                  <th>Defecto</th>
                  <th>Responsable</th>
                  <th class="text-right">Cantidad afectada</th>
                  <th>Vence</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={non_conformity <- @report.open_non_conformities}>
                  <td>{non_conformity.work_item.description}</td>
                  <td class="font-medium">{non_conformity.defect}</td>
                  <td>{non_conformity.responsible_name}</td>
                  <td class="text-right">
                    {non_conformity.affected_quantity} {non_conformity.work_item.unit}
                  </td>
                  <td>{non_conformity.due_on || "Sin fecha"}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="py-7" aria-label="Estimaciones y costo acumulado">
          <div class="flex flex-wrap items-end justify-between gap-4">
            <div>
              <p class="text-sm font-medium text-primary">Costo</p>
              <h2 class="mt-1 text-xl font-semibold">Estimaciones y costo acumulado</h2>
            </div>
            <span class="badge badge-outline">{length(@report.estimates)} estimaciones</span>
          </div>

          <div class="mt-5 grid gap-4 sm:grid-cols-3">
            <div class="border-l-2 border-primary pl-4">
              <dt class="text-sm text-base-content/60">Contratado</dt>
              <dd class="mt-1 font-semibold">{@report.cost_summary.totals.contracted_amount}</dd>
            </div>
            <div class="border-l-2 border-success pl-4">
              <dt class="text-sm text-base-content/60">Estimado acumulado</dt>
              <dd class="mt-1 font-semibold">{@report.cost_summary.totals.estimated_amount}</dd>
            </div>
            <div class="border-l-2 border-warning pl-4">
              <dt class="text-sm text-base-content/60">Saldo basico</dt>
              <dd class="mt-1 font-semibold">{@report.cost_summary.totals.balance}</dd>
            </div>
          </div>

          <div
            :if={@report.estimates == []}
            id="internal-report-estimates-empty"
            class="mt-5 grid min-h-32 place-items-center border-y border-base-300 text-center"
          >
            <div>
              <.icon name="hero-document-plus" class="mx-auto size-8 text-base-content/35" />
              <p class="mt-3 font-medium">Sin estimaciones generadas</p>
            </div>
          </div>

          <div :if={@report.estimates != []} class="mt-5 overflow-x-auto">
            <table class="table">
              <thead>
                <tr>
                  <th>Estimacion</th>
                  <th>Subcontrato</th>
                  <th>Estado</th>
                  <th class="text-right">Lineas</th>
                  <th class="text-right">Monto</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={estimate <- @report.estimates}>
                  <td class="font-medium">#{estimate.id}</td>
                  <td>
                    {estimate.subcontract.name}
                    <p class="mt-1 text-xs text-base-content/55">
                      {estimate.subcontract.counterparty.name}
                    </p>
                  </td>
                  <td>{estimate_status_label(estimate.status)}</td>
                  <td class="text-right">{length(estimate.lines)}</td>
                  <td class="text-right">{estimate.amount}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </section>
    </Layouts.app>
    """
  end

  defp budget_status_label(%{status: :approved}), do: "Aprobado"
  defp budget_status_label(%{status: :draft}), do: "Borrador"
  defp budget_status_label(_budget), do: "Pendiente"

  defp estimate_status_label(:generated), do: "Generada"
end
