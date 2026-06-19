defmodule CivoraWeb.PerformanceSheetLive.Index do
  use CivoraWeb, :live_view

  alias Civora.Budget
  alias Civora.Budget.{PerformanceSheet, PerformanceSheetResource}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Fichas de rendimiento")
     |> assign(:performance_sheets, Budget.list_performance_sheets(socket.assigns.current_scope))
     |> assign(
       :can_manage,
       Budget.can_manage_performance_sheets?(socket.assigns.current_scope)
     )
     |> assign(:resource_category_options, resource_category_options())
     |> assign_sheet_form(Budget.change_performance_sheet(empty_sheet()))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section>
        <.link
          navigate={~p"/"}
          class="inline-flex items-center gap-2 text-sm text-base-content/65 hover:text-base-content"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Proyectos
        </.link>
        <div class="mt-6 border-b border-base-300 pb-6">
          <p class="text-sm font-medium text-primary">Biblioteca reutilizable</p>
          <h1 class="mt-1 text-3xl font-semibold">Fichas de rendimiento</h1>
          <p class="mt-2 max-w-2xl text-sm text-base-content/65">
            Plantillas globales de recursos requeridos para producir una unidad de obra.
          </p>
        </div>
      </section>

      <section class="grid gap-8 py-4 lg:grid-cols-[minmax(0,1fr)_25rem]">
        <div aria-label="Fichas de rendimiento">
          <div
            :if={@performance_sheets == []}
            id="performance-sheets-empty"
            class="grid min-h-48 place-items-center border-b border-base-300 text-center"
          >
            <div>
              <.icon name="hero-calculator" class="mx-auto size-8 text-base-content/35" />
              <p class="mt-3 font-medium">Sin fichas registradas</p>
            </div>
          </div>

          <.link
            :for={sheet <- @performance_sheets}
            id={"performance-sheet-#{sheet.id}"}
            navigate={~p"/performance-sheets/#{sheet}"}
            class="block border-b border-base-300 py-5 hover:bg-base-200/40"
          >
            <div class="flex flex-wrap items-start justify-between gap-3">
              <div>
                <h2 class="font-semibold">{sheet.name}</h2>
                <p class="mt-1 line-clamp-2 text-sm text-base-content/60">{sheet.description}</p>
              </div>
              <div class="text-right">
                <span class="badge badge-outline">por {sheet.unit}</span>
                <p class="mt-2 text-xs text-base-content/55">{length(sheet.resources)} recursos</p>
              </div>
            </div>
          </.link>
        </div>

        <aside :if={@can_manage} class="border-l-0 border-base-300 lg:border-l lg:pl-8">
          <h2 class="text-base font-semibold">Nueva ficha</h2>
          <.form
            for={@sheet_form}
            id="performance-sheet-form"
            phx-submit="save"
            class="mt-5 space-y-4"
          >
            <.input field={@sheet_form[:name]} label="Nombre" required />
            <.input
              field={@sheet_form[:description]}
              type="textarea"
              label="Descripcion"
              rows="3"
              required
            />
            <.input field={@sheet_form[:unit]} label="Unidad producida" placeholder="m2" required />
            <div class="grid grid-cols-2 gap-3">
              <.input
                field={@sheet_form[:productivity]}
                type="number"
                label="Productividad diaria"
                min="0.0001"
                step="0.0001"
              />
              <.input
                field={@sheet_form[:waste_percentage]}
                type="number"
                label="Desperdicio (%)"
                min="0"
                max="100"
                step="0.0001"
              />
            </div>

            <fieldset class="space-y-4 border-t border-base-300 pt-4">
              <legend class="text-sm font-semibold">Recursos basicos</legend>
              <.inputs_for :let={resource_form} field={@sheet_form[:resources]}>
                <div class="grid grid-cols-2 gap-3 rounded-box border border-base-300 p-3">
                  <.input
                    field={resource_form[:category]}
                    type="select"
                    label="Tipo"
                    prompt="Seleccionar"
                    options={@resource_category_options}
                  />
                  <.input field={resource_form[:name]} label="Recurso" />
                  <.input field={resource_form[:unit]} label="Unidad" placeholder="unidad" />
                  <.input
                    field={resource_form[:quantity]}
                    type="number"
                    label="Cantidad"
                    min="0.0001"
                    step="0.0001"
                  />
                </div>
              </.inputs_for>
            </fieldset>

            <.button variant="primary" class="btn btn-primary w-full" phx-disable-with="Creando...">
              <.icon name="hero-plus" class="size-4" /> Crear ficha
            </.button>
          </.form>
        </aside>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("save", %{"performance_sheet" => params}, socket) do
    case Budget.create_performance_sheet(socket.assigns.current_scope, params) do
      {:ok, _sheet} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ficha de rendimiento creada correctamente.")
         |> redirect(to: ~p"/performance-sheets")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_sheet_form(socket, changeset)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "No tienes permiso para crear fichas.")}
    end
  end

  defp empty_sheet do
    %PerformanceSheet{resources: List.duplicate(%PerformanceSheetResource{}, 3)}
  end

  defp resource_category_options do
    Enum.map(Budget.resource_categories(), &{Budget.resource_category_label(&1), &1})
  end

  defp assign_sheet_form(socket, changeset), do: assign(socket, :sheet_form, to_form(changeset))
end
