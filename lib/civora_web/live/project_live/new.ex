defmodule CivoraWeb.ProjectLive.New do
  use CivoraWeb, :live_view

  alias Civora.Projects
  alias Civora.Projects.Project

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Nuevo proyecto")
     |> assign(:status_options, status_options())
     |> assign_form(Projects.change_project(%Project{}))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="mx-auto max-w-3xl">
        <.link
          navigate={~p"/"}
          class="inline-flex items-center gap-2 text-sm text-base-content/65 hover:text-base-content"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Proyectos
        </.link>

        <div class="mt-6 border-b border-base-300 pb-6">
          <p class="text-sm font-medium text-primary">Base operativa</p>
          <h1 class="mt-2 text-3xl font-semibold">Nuevo proyecto</h1>
        </div>

        <.form
          for={@form}
          id="project-form"
          phx-change="validate"
          phx-submit="save"
          class="grid gap-5 py-8 sm:grid-cols-2"
        >
          <.input field={@form[:name]} label="Nombre" autocomplete="off" required />
          <.input
            field={@form[:client_reference]}
            label="Cliente o referencia"
            autocomplete="off"
            required
          />
          <.input
            field={@form[:status]}
            type="select"
            label="Estado"
            options={@status_options}
            required
          />
          <div class="hidden sm:block"></div>
          <div class="sm:col-span-2">
            <.input
              field={@form[:description]}
              type="textarea"
              label="Descripcion"
              rows="5"
              required
            />
          </div>
          <div class="flex justify-end gap-3 border-t border-base-300 pt-6 sm:col-span-2">
            <.button navigate={~p"/"} class="btn btn-ghost">Cancelar</.button>
            <.button variant="primary" phx-disable-with="Creando...">
              Crear proyecto
            </.button>
          </div>
        </.form>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate", %{"project" => params}, socket) do
    changeset =
      %Project{}
      |> Projects.change_project(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"project" => params}, socket) do
    case Projects.create_project(socket.assigns.current_scope, params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Proyecto creado correctamente.")
         |> push_navigate(to: ~p"/projects/#{project}")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp status_options do
    Enum.map(Projects.available_statuses(), &{Projects.status_label(&1), &1})
  end
end
