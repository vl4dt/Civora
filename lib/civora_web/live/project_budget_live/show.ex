defmodule CivoraWeb.ProjectBudgetLive.Show do
  use CivoraWeb, :live_view

  alias Civora.Budget
  alias Civora.Projects
  alias Civora.Projects.Project

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    with {:ok, project} <- Projects.get_project(socket.assigns.current_scope, project_id),
         {:ok, project_budget} <- Budget.get_project_budget(socket.assigns.current_scope, project) do
      {:ok,
       socket
       |> assign(:page_title, "Presupuesto - #{project.name}")
       |> assign(:project, project)
       |> assign(:project_budget, project_budget)
       |> assign(
         :can_manage_budget,
         Projects.authorized?(socket.assigns.current_scope, project, :manage_budget)
       )}
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

        <div class="mt-6 flex flex-col gap-4 border-b border-base-300 pb-7 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p class="text-sm font-medium text-primary">Linea base financiera</p>
            <h1 class="mt-1 text-3xl font-semibold">Presupuesto del proyecto</h1>
            <p class="mt-2 max-w-2xl text-sm leading-6 text-base-content/65">
              Copia historica de las partidas y fichas presupuestadas usadas para aprobar el presupuesto.
            </p>
          </div>

          <span :if={@project_budget} class={budget_status_class(@project_budget.status)}>
            {budget_status_label(@project_budget.status)}
          </span>
        </div>

        <div :if={is_nil(@project_budget)} id="project-budget-empty" class="py-10 text-center">
          <.icon name="hero-banknotes" class="mx-auto size-9 text-base-content/35" />
          <h2 class="mt-3 font-semibold">Presupuesto inicial pendiente</h2>
          <p class="mx-auto mt-2 max-w-xl text-sm leading-6 text-base-content/65">
            Genera una copia de las partidas actuales y de sus fichas presupuestadas. Debe existir al menos una partida.
          </p>
          <.button
            :if={@can_manage_budget}
            id="create-project-budget"
            variant="primary"
            class="mt-5"
            phx-click="create_budget"
            phx-disable-with="Generando..."
          >
            Generar presupuesto inicial
          </.button>
        </div>

        <div :if={@project_budget}>
          <div
            :if={@project_budget.status == :approved}
            id="approved-budget-notice"
            class="my-6 rounded-box border border-success/30 bg-success/10 p-4"
          >
            <p class="font-semibold text-success">Linea base aprobada e inalterable</p>
            <p class="mt-1 text-sm text-base-content/65">
              Aprobada por {@project_budget.approved_by.email} el {format_datetime(
                @project_budget.approved_at
              )}. Su contenido ya no admite edicion directa.
            </p>
          </div>

          <div
            :if={@project_budget.status == :draft}
            class="my-6 flex flex-col gap-4 rounded-box border border-warning/30 bg-warning/10 p-4 sm:flex-row sm:items-center sm:justify-between"
          >
            <div>
              <p class="font-semibold">Borrador listo para revision</p>
              <p class="mt-1 text-sm text-base-content/65">
                La aprobacion es definitiva y bloquea la edicion directa del presupuesto.
              </p>
            </div>
            <.button
              :if={@can_manage_budget}
              id="approve-project-budget"
              variant="primary"
              phx-click="approve_budget"
              data-confirm="Aprobar este presupuesto como linea base inalterable?"
              phx-disable-with="Aprobando..."
            >
              Aprobar presupuesto
            </.button>
          </div>

          <section aria-label="Partidas del presupuesto">
            <article
              :for={line <- @project_budget.lines}
              id={"project-budget-line-#{line.id}"}
              class="border-b border-base-300 py-6"
            >
              <div class="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <p class="text-sm text-primary">{line.phase_name}</p>
                  <h2 class="mt-1 font-semibold">{line.description}</h2>
                </div>
                <span class="badge badge-outline">{line.quantity} {line.unit}</span>
              </div>

              <div :if={line.sheet_name} class="mt-4 rounded-box bg-base-200/60 p-4">
                <div class="flex flex-wrap items-center justify-between gap-2">
                  <h3 class="font-medium">{line.sheet_name}</h3>
                  <span class="text-sm text-base-content/60">por {line.sheet_unit}</span>
                </div>
                <p class="mt-2 text-sm leading-6 text-base-content/65">{line.sheet_description}</p>
                <div :if={line.resources != []} class="mt-3 overflow-x-auto">
                  <table class="table table-sm">
                    <thead>
                      <tr>
                        <th>Tipo</th><th>Recurso</th><th class="text-right">Cantidad</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr :for={resource <- line.resources}>
                        <td>{Budget.resource_category_label(resource.category)}</td>
                        <td>{resource.name}</td>
                        <td class="text-right">{resource.quantity} {resource.unit}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <p :if={is_nil(line.sheet_name)} class="mt-3 text-sm text-warning">
                Partida sin ficha presupuestada al generar esta version.
              </p>
            </article>
          </section>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("create_budget", _params, socket) do
    case Budget.create_project_budget(socket.assigns.current_scope, socket.assigns.project) do
      {:ok, project_budget} ->
        {:noreply,
         socket
         |> assign(:project_budget, project_budget)
         |> put_flash(:info, "Presupuesto inicial generado correctamente.")}

      {:error, :no_work_items} ->
        {:noreply,
         put_flash(socket, :error, "Agrega al menos una partida antes de generar el presupuesto.")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "El proyecto ya tiene un presupuesto inicial.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "No se pudo generar el presupuesto.")}
    end
  end

  def handle_event("approve_budget", _params, socket) do
    case Budget.approve_project_budget(
           socket.assigns.current_scope,
           socket.assigns.project,
           socket.assigns.project_budget
         ) do
      {:ok, project_budget} ->
        {:noreply,
         socket
         |> assign(:project_budget, project_budget)
         |> put_flash(:info, "Presupuesto aprobado como linea base inalterable.")}

      {:error, :already_approved} ->
        {:noreply, put_flash(socket, :error, "El presupuesto ya fue aprobado.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "No se pudo aprobar el presupuesto.")}
    end
  end

  defp budget_status_label(:draft), do: "Borrador"
  defp budget_status_label(:approved), do: "Aprobado"
  defp budget_status_class(:draft), do: "badge badge-warning badge-outline"
  defp budget_status_class(:approved), do: "badge badge-success badge-outline"

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%d/%m/%Y %H:%M UTC")
  end
end
