defmodule CivoraWeb.WorkItemLive.Index do
  use CivoraWeb, :live_view

  alias Civora.Budget
  alias Civora.Budget.WorkItem
  alias Civora.Projects
  alias Civora.Projects.Project

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    with {:ok, project} <- Projects.get_project(socket.assigns.current_scope, project_id),
         {:ok, phases} <- Projects.list_project_phases(socket.assigns.current_scope, project),
         {:ok, work_items} <- Budget.list_work_items(socket.assigns.current_scope, project) do
      {:ok,
       socket
       |> assign(:page_title, "Partidas - #{project.name}")
       |> assign(:project, project)
       |> assign(:phases, phases)
       |> assign(:work_items, work_items)
       |> assign(
         :can_manage_budget,
         Projects.authorized?(socket.assigns.current_scope, project, :manage_budget)
       )
       |> assign_work_item_form(Budget.change_work_item(%WorkItem{}))}
    else
      {:error, _reason} -> raise Ecto.NoResultsError, queryable: Project
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section>
        <.link
          navigate={~p"/projects/#{@project}"}
          class="inline-flex items-center gap-2 text-sm text-base-content/65 hover:text-base-content"
        >
          <.icon name="hero-arrow-left" class="size-4" /> {@project.name}
        </.link>
        <div class="mt-6 border-b border-base-300 pb-6">
          <p class="text-sm font-medium text-primary">Presupuesto</p>
          <h1 class="mt-1 text-3xl font-semibold">Partidas de obra</h1>
          <p class="mt-2 text-sm text-base-content/65">
            Unidades economicas y de control de calidad del proyecto.
          </p>
        </div>
      </section>

      <section class="grid gap-8 py-4 lg:grid-cols-[minmax(0,1fr)_22rem]">
        <div aria-label="Partidas de obra">
          <div
            :if={@work_items == []}
            id="work-items-empty"
            class="grid min-h-48 place-items-center border-b border-base-300 text-center"
          >
            <div>
              <.icon name="hero-clipboard-document-list" class="mx-auto size-8 text-base-content/35" />
              <p class="mt-3 font-medium">Sin partidas registradas</p>
            </div>
          </div>

          <.link
            :for={item <- @work_items}
            id={"work-item-#{item.id}"}
            navigate={~p"/projects/#{@project}/work-items/#{item}"}
            class="block border-b border-base-300 py-5 hover:bg-base-200/40"
          >
            <div class="flex flex-wrap items-start justify-between gap-3">
              <div>
                <h2 class="font-semibold">{item.description}</h2>
                <p class="mt-1 text-sm text-base-content/60">{item.project_phase.name}</p>
              </div>
              <span class="badge badge-outline">{item.quantity} {item.unit}</span>
            </div>
          </.link>
        </div>

        <aside :if={@can_manage_budget} class="border-l-0 border-base-300 lg:border-l lg:pl-8">
          <h2 class="text-base font-semibold">Agregar partida</h2>
          <p :if={@phases == []} class="mt-4 text-sm leading-6 text-warning">
            Crea una fase del proyecto antes de agregar partidas.
          </p>

          <.form
            :if={@phases != []}
            for={@work_item_form}
            id="work-item-form"
            phx-change="validate"
            phx-submit="save"
            class="mt-5 space-y-4"
          >
            <.input
              field={@work_item_form[:project_phase_id]}
              type="select"
              label="Fase"
              prompt="Seleccionar"
              options={Enum.map(@phases, &{&1.name, &1.id})}
              required
            />
            <.input
              field={@work_item_form[:description]}
              type="textarea"
              label="Descripcion"
              rows="4"
              required
            />
            <div class="grid grid-cols-2 gap-3">
              <.input field={@work_item_form[:unit]} label="Unidad" placeholder="m2" required />
              <.input
                field={@work_item_form[:quantity]}
                type="number"
                label="Cantidad"
                min="0.0001"
                step="0.0001"
                required
              />
            </div>
            <.button variant="primary" class="btn btn-primary w-full" phx-disable-with="Agregando...">
              <.icon name="hero-plus" class="size-4" /> Agregar partida
            </.button>
          </.form>
        </aside>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate", %{"work_item" => params}, socket) do
    changeset =
      %WorkItem{}
      |> Budget.change_work_item(Map.put(params, "project_id", socket.assigns.project.id))
      |> Map.put(:action, :validate)

    {:noreply, assign_work_item_form(socket, changeset)}
  end

  def handle_event("save", %{"work_item" => params}, socket) do
    case Budget.create_work_item(socket.assigns.current_scope, socket.assigns.project, params) do
      {:ok, item} ->
        {:noreply,
         socket
         |> update(:work_items, &(&1 ++ [item]))
         |> assign_work_item_form(Budget.change_work_item(%WorkItem{}))
         |> put_flash(:info, "Partida agregada correctamente.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_work_item_form(socket, changeset)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "No tienes permiso para agregar partidas.")}
    end
  end

  defp assign_work_item_form(socket, changeset),
    do: assign(socket, :work_item_form, to_form(changeset))
end
