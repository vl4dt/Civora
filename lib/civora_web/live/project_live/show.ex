defmodule CivoraWeb.ProjectLive.Show do
  use CivoraWeb, :live_view

  alias Civora.Projects
  alias Civora.Projects.{Project, ProjectPhase}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    with {:ok, project} <- Projects.get_project(socket.assigns.current_scope, id),
         {:ok, phases} <- Projects.list_project_phases(socket.assigns.current_scope, project) do
      {:ok,
       socket
       |> assign(:page_title, project.name)
       |> assign(:project, project)
       |> assign(:phases, phases)
       |> assign(
         :can_manage_project,
         Projects.authorized?(socket.assigns.current_scope, project, :manage_project)
       )
       |> assign(:phase_type_options, phase_type_options())
       |> assign_phase_form(Projects.change_project_phase(%ProjectPhase{}))}
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
          navigate={~p"/"}
          class="inline-flex items-center gap-2 text-sm text-base-content/65 hover:text-base-content"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Proyectos
        </.link>

        <div class="mt-6 flex flex-col gap-5 border-b border-base-300 pb-8 sm:flex-row sm:items-start sm:justify-between">
          <div class="min-w-0">
            <p class="text-sm text-base-content/60">{@project.client_reference}</p>

            <h1 class="mt-2 text-3xl font-semibold">{@project.name}</h1>

            <p class="mt-3 max-w-3xl text-sm leading-6 text-base-content/70">
              {@project.description}
            </p>
          </div>

          <div class="flex shrink-0 items-center gap-3">
            <.link
              navigate={~p"/projects/#{@project}/subcontracts"}
              class="btn btn-ghost btn-sm"
            >
              <.icon name="hero-document-text" class="size-4" /> Subcontratos
            </.link>
            <.link navigate={~p"/projects/#{@project}/budget"} class="btn btn-ghost btn-sm">
              <.icon name="hero-banknotes" class="size-4" /> Presupuesto
            </.link>
            <.link
              navigate={~p"/projects/#{@project}/work-items"}
              class="btn btn-ghost btn-sm"
            >
              <.icon name="hero-clipboard-document-list" class="size-4" /> Partidas
            </.link>

            <.link
              navigate={~p"/projects/#{@project}/audit"}
              class="btn btn-ghost btn-sm"
            >
              <.icon name="hero-clock" class="size-4" /> Auditoria
            </.link>

            <span class="badge badge-outline">
              {Projects.status_label(@project.status)}
            </span>
          </div>
        </div>
      </section>

      <section class="grid gap-8 py-4 lg:grid-cols-[minmax(0,1fr)_22rem]">
        <div>
          <div class="border-b border-base-300 pb-4">
            <p class="text-sm font-medium text-primary">Alcance contratado</p>

            <h2 class="mt-1 text-xl font-semibold">Fases del proyecto</h2>
          </div>

          <div
            :if={@phases == []}
            class="grid min-h-48 place-items-center border-b border-base-300 text-center"
          >
            <div>
              <.icon name="hero-squares-2x2" class="mx-auto size-8 text-base-content/35" />
              <p class="mt-3 font-medium">Sin fases registradas</p>
            </div>
          </div>

          <article :for={phase <- @phases} class="border-b border-base-300 py-5">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <h3 class="font-semibold">{phase.name}</h3>

              <span class="badge badge-ghost badge-sm">
                {Projects.phase_type_label(phase.phase_type)}
              </span>
            </div>

            <p class="mt-2 text-sm leading-6 text-base-content/65">{phase.description}</p>
          </article>
        </div>

        <aside :if={@can_manage_project} class="border-l-0 border-base-300 lg:border-l lg:pl-8">
          <h2 class="text-base font-semibold">Agregar fase</h2>

          <.form
            for={@phase_form}
            id="phase-form"
            phx-change="validate_phase"
            phx-submit="save_phase"
            class="mt-5 space-y-4"
          >
            <.input field={@phase_form[:name]} label="Nombre" autocomplete="off" required />
            <.input
              field={@phase_form[:phase_type]}
              type="select"
              label="Tipo de fase"
              prompt="Seleccionar"
              options={@phase_type_options}
              required
            />
            <.input
              field={@phase_form[:description]}
              type="textarea"
              label="Descripcion"
              rows="4"
              required
            />
            <.button
              variant="primary"
              class="btn btn-primary w-full"
              phx-disable-with="Agregando..."
            >
              <.icon name="hero-plus" class="size-4" /> Agregar fase
            </.button>
          </.form>
        </aside>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate_phase", %{"project_phase" => params}, socket) do
    params = Map.put(params, "project_id", socket.assigns.project.id)

    changeset =
      %ProjectPhase{}
      |> Projects.change_project_phase(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_phase_form(socket, changeset)}
  end

  def handle_event("save_phase", %{"project_phase" => params}, socket) do
    case Projects.create_project_phase(
           socket.assigns.current_scope,
           socket.assigns.project,
           params
         ) do
      {:ok, phase} ->
        {:noreply,
         socket
         |> update(:phases, &(&1 ++ [phase]))
         |> assign_phase_form(Projects.change_project_phase(%ProjectPhase{}))
         |> put_flash(:info, "Fase agregada correctamente.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_phase_form(socket, changeset)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "No tienes permiso para agregar fases.")}
    end
  end

  defp assign_phase_form(socket, changeset) do
    assign(socket, :phase_form, to_form(changeset))
  end

  defp phase_type_options do
    Enum.map(Projects.available_phase_types(), &{Projects.phase_type_label(&1), &1})
  end
end
