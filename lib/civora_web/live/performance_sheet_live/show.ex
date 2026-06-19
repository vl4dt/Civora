defmodule CivoraWeb.PerformanceSheetLive.Show do
  use CivoraWeb, :live_view

  alias Civora.Budget
  alias Civora.Budget.PerformanceSheet

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Budget.get_performance_sheet(socket.assigns.current_scope, id) do
      {:ok, sheet} ->
        {:ok,
         socket
         |> assign(:page_title, sheet.name)
         |> assign(:performance_sheet, sheet)}

      {:error, :not_found} ->
        raise Ecto.NoResultsError, queryable: PerformanceSheet
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="max-w-4xl">
        <.link
          navigate={~p"/performance-sheets"}
          class="inline-flex items-center gap-2 text-sm text-base-content/65 hover:text-base-content"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Fichas de rendimiento
        </.link>
        <div class="mt-6 border-b border-base-300 pb-7">
          <p class="text-sm font-medium text-primary">Plantilla reutilizable</p>
          <h1 class="mt-2 text-3xl font-semibold">{@performance_sheet.name}</h1>
          <p class="mt-3 text-sm leading-6 text-base-content/65">{@performance_sheet.description}</p>
        </div>

        <dl class="grid gap-6 border-b border-base-300 py-7 sm:grid-cols-3">
          <div>
            <dt class="text-sm text-base-content/60">Unidad producida</dt><dd class="mt-1 text-lg font-semibold">
              {@performance_sheet.unit}
            </dd>
          </div>
          <div>
            <dt class="text-sm text-base-content/60">Productividad diaria</dt><dd class="mt-1 text-lg font-semibold">
              {@performance_sheet.productivity || "No aplica"}
            </dd>
          </div>
          <div>
            <dt class="text-sm text-base-content/60">Desperdicio</dt><dd class="mt-1 text-lg font-semibold">
              {percentage(@performance_sheet.waste_percentage)}
            </dd>
          </div>
        </dl>

        <section class="py-7" aria-label="Recursos basicos">
          <h2 class="text-xl font-semibold">Recursos basicos</h2>
          <div class="mt-4 overflow-x-auto">
            <table class="table">
              <thead>
                <tr>
                  <th>Tipo</th><th>Recurso</th><th class="text-right">Cantidad</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={resource <- @performance_sheet.resources}>
                  <td>{Budget.resource_category_label(resource.category)}</td>
                  <td>{resource.name}</td>
                  <td class="text-right font-medium">{resource.quantity} {resource.unit}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </section>
    </Layouts.app>
    """
  end

  defp percentage(nil), do: "No aplica"
  defp percentage(value), do: "#{value}%"
end
