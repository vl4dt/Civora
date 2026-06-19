defmodule CivoraWeb.AuditLive.Index do
  use CivoraWeb, :live_view

  alias Civora.Audit
  alias Civora.Projects
  alias Civora.Projects.Project

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    with {:ok, project} <- Projects.get_project(socket.assigns.current_scope, id),
         {:ok, events} <- Audit.list_project_events(socket.assigns.current_scope, project) do
      {:ok,
       socket
       |> assign(:page_title, "Auditoria - #{project.name}")
       |> assign(:project, project)
       |> assign(:events, events)}
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

        <div class="mt-6 border-b border-base-300 pb-8">
          <p class="text-sm font-medium text-primary">Registro inalterable</p>
          <h1 class="mt-2 text-3xl font-semibold">Auditoria</h1>
          <p class="mt-2 max-w-2xl text-sm leading-6 text-base-content/65">
            Acciones criticas registradas para este proyecto.
          </p>
        </div>
      </section>

      <section aria-label="Eventos de auditoria">
        <div class="hidden grid-cols-[minmax(0,1.5fr)_minmax(0,1fr)_minmax(0,1fr)_auto] gap-6 border-b border-base-300 px-3 pb-3 text-xs font-medium uppercase text-base-content/50 md:grid">
          <span>Accion</span>
          <span>Entidad</span>
          <span>Actor</span>
          <span>Fecha</span>
        </div>

        <article
          :for={event <- @events}
          class="grid gap-3 border-b border-base-300 px-3 py-5 md:grid-cols-[minmax(0,1.5fr)_minmax(0,1fr)_minmax(0,1fr)_auto] md:items-center md:gap-6"
        >
          <div>
            <p class="font-semibold">{Audit.action_label(event.action)}</p>
            <p :if={event.reason} class="mt-1 text-sm text-base-content/60">{event.reason}</p>
          </div>
          <p class="text-sm text-base-content/70">
            {entity_label(event.entity_type)} #{event.entity_id}
          </p>
          <p class="truncate text-sm text-base-content/70">{event.actor.email}</p>
          <time class="text-sm text-base-content/60" datetime={DateTime.to_iso8601(event.inserted_at)}>
            {Calendar.strftime(event.inserted_at, "%Y-%m-%d %H:%M UTC")}
          </time>
        </article>
      </section>
    </Layouts.app>
    """
  end

  defp entity_label("project"), do: "Proyecto"
  defp entity_label("project_phase"), do: "Fase"
  defp entity_label("project_assignment"), do: "Asignacion"
  defp entity_label("budget"), do: "Presupuesto"
  defp entity_label("quality_control"), do: "Control de calidad"
  defp entity_label("estimate"), do: "Estimacion"
  defp entity_label(entity_type), do: entity_type
end
