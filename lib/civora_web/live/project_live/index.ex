defmodule CivoraWeb.ProjectLive.Index do
  use CivoraWeb, :live_view

  alias Civora.Projects

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Proyectos")
     |> assign(:projects, Projects.list_projects(socket.assigns.current_scope))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="flex flex-col gap-5 border-b border-base-300 pb-8 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p class="text-sm font-medium text-primary">Base operativa</p>
          <h1 class="mt-2 text-3xl font-semibold">Proyectos</h1>
          <p class="mt-2 max-w-2xl text-sm leading-6 text-base-content/65">
            Proyectos asignados a tu cuenta.
          </p>
        </div>
        <.button navigate={~p"/projects/new"} variant="primary">
          <.icon name="hero-plus" class="size-4" /> Nuevo proyecto
        </.button>
      </section>

      <section
        :if={@projects == []}
        class="grid min-h-80 place-items-center border-b border-base-300 py-16 text-center"
      >
        <div class="max-w-md">
          <.icon name="hero-building-office-2" class="mx-auto size-10 text-base-content/35" />
          <h2 class="mt-4 text-lg font-semibold">Sin proyectos asignados</h2>
          <p class="mt-2 text-sm leading-6 text-base-content/60">
            Crea el primer proyecto para comenzar la operacion.
          </p>
        </div>
      </section>

      <section :if={@projects != []} aria-label="Proyectos asignados">
        <div class="hidden grid-cols-[minmax(0,2fr)_minmax(0,1fr)_auto] gap-6 border-b border-base-300 px-3 pb-3 text-xs font-medium uppercase text-base-content/50 sm:grid">
          <span>Proyecto</span>
          <span>Cliente o referencia</span>
          <span>Estado</span>
        </div>
        <.link
          :for={project <- @projects}
          navigate={~p"/projects/#{project}"}
          class="group grid gap-2 border-b border-base-300 px-3 py-5 transition hover:bg-base-200/60 sm:grid-cols-[minmax(0,2fr)_minmax(0,1fr)_auto] sm:items-center sm:gap-6"
        >
          <div class="min-w-0">
            <h2 class="truncate font-semibold group-hover:text-primary">{project.name}</h2>
            <p class="mt-1 line-clamp-1 text-sm text-base-content/60">{project.description}</p>
          </div>
          <p class="truncate text-sm text-base-content/70">{project.client_reference}</p>
          <span class={["badge badge-sm", status_class(project.status)]}>
            {Projects.status_label(project.status)}
          </span>
        </.link>
      </section>
    </Layouts.app>
    """
  end

  defp status_class(:activo), do: "badge-success"
  defp status_class(:pausado), do: "badge-warning"
  defp status_class(:cancelado), do: "badge-error"
  defp status_class(_status), do: "badge-ghost"
end
