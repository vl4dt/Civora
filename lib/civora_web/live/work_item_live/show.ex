defmodule CivoraWeb.WorkItemLive.Show do
  use CivoraWeb, :live_view

  alias Civora.Budget
  alias Civora.Budget.{BudgetedPerformanceSheet, WorkItem}
  alias Civora.Execution
  alias Civora.Execution.WorkActivity
  alias Civora.Projects

  @impl true
  def mount(%{"project_id" => project_id, "id" => id}, _session, socket) do
    with {:ok, project} <- Projects.get_project(socket.assigns.current_scope, project_id),
         {:ok, item} <- Budget.get_work_item(socket.assigns.current_scope, project, id),
         {:ok, activities} <-
           Execution.list_work_item_activities(socket.assigns.current_scope, project, item),
         {:ok, budgeted_sheet} <-
           Budget.get_budgeted_performance_sheet_for_work_item(
             socket.assigns.current_scope,
             project,
             item
           ) do
      {:ok,
       socket
       |> assign(:page_title, item.description)
       |> assign(:project, project)
       |> assign(:work_item, item)
       |> assign(:activities, activities)
       |> assign(:budgeted_sheet, budgeted_sheet)
       |> assign(:budget_editable, Budget.budget_editable?(project))
       |> assign(:performance_sheet_options, performance_sheet_options(socket))
       |> assign(
         :can_manage_activities,
         Projects.authorized?(socket.assigns.current_scope, project, :manage_activities)
       )
       |> assign(
         :can_manage_budget,
         Projects.authorized?(socket.assigns.current_scope, project, :manage_budget)
       )
       |> assign_activity_form(Execution.change_work_activity(%WorkActivity{}))
       |> assign_source_form()
       |> assign_budgeted_sheet_form(budgeted_sheet)}
    else
      {:error, _reason} -> raise Ecto.NoResultsError, queryable: WorkItem
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="max-w-4xl">
        <.link
          navigate={~p"/projects/#{@project}/work-items"}
          class="inline-flex items-center gap-2 text-sm text-base-content/65 hover:text-base-content"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Partidas de obra
        </.link>

        <div class="mt-6 border-b border-base-300 pb-7">
          <p class="text-sm font-medium text-primary">{@work_item.project_phase.name}</p>

          <h1 class="mt-2 text-3xl font-semibold">{@work_item.description}</h1>
        </div>

        <dl class="grid gap-6 border-b border-base-300 py-7 sm:grid-cols-2">
          <div>
            <dt class="text-sm text-base-content/60">Cantidad</dt>

            <dd class="mt-1 text-xl font-semibold">{@work_item.quantity}</dd>
          </div>

          <div>
            <dt class="text-sm text-base-content/60">Unidad</dt>

            <dd class="mt-1 text-xl font-semibold">{@work_item.unit}</dd>
          </div>
        </dl>

        <section class="border-b border-base-300 py-7" aria-label="Actividades de obra">
          <div class="grid gap-8 lg:grid-cols-[minmax(0,1fr)_20rem]">
            <div>
              <p class="text-sm font-medium text-primary">Ejecucion</p>

              <h2 class="mt-1 text-xl font-semibold">Actividades de obra</h2>

              <p class="mt-2 text-sm text-base-content/65">
                Sectores o frentes de trabajo asociados exclusivamente a esta partida.
              </p>

              <div
                :if={@activities == []}
                id="work-activities-empty"
                class="mt-6 rounded-box border border-dashed border-base-300 p-6 text-sm text-base-content/60"
              >
                Sin actividades registradas para esta partida.
              </div>

              <div
                :for={activity <- @activities}
                id={"work-activity-#{activity.id}"}
                class="mt-4 rounded-box border border-base-300 p-4"
              >
                <p class="font-semibold">{activity.location_sector}</p>
                <p class="mt-2 text-sm leading-6 text-base-content/65">{activity.description}</p>
              </div>
            </div>

            <aside :if={@can_manage_activities}>
              <h3 class="text-base font-semibold">Agregar actividad</h3>

              <.form
                for={@activity_form}
                id="work-activity-form"
                phx-change="validate_activity"
                phx-submit="save_activity"
                class="mt-5 space-y-4"
              >
                <.input
                  field={@activity_form[:location_sector]}
                  label="Ubicacion o sector"
                  placeholder="Nivel 2 / eje A-C"
                  required
                />
                <.input
                  field={@activity_form[:description]}
                  type="textarea"
                  label="Descripcion"
                  rows="4"
                  required
                />

                <.button variant="primary" class="w-full" phx-disable-with="Agregando...">
                  <.icon name="hero-plus" class="size-4" /> Agregar actividad
                </.button>
              </.form>
            </aside>
          </div>
        </section>

        <section class="py-7" aria-label="Ficha presupuestada">
          <div class="border-b border-base-300 pb-4">
            <p class="text-sm font-medium text-primary">Presupuesto del proyecto</p>

            <h2 class="mt-1 text-xl font-semibold">Ficha presupuestada</h2>
          </div>

          <div :if={is_nil(@budgeted_sheet)} class="py-6">
            <p class="text-sm text-base-content/65">
              Aun no se ha generado una copia historica para esta partida.
            </p>

            <.form
              :if={@can_manage_budget && @budget_editable && @performance_sheet_options != []}
              for={@source_form}
              id="budgeted-sheet-source-form"
              phx-submit="create_budgeted_sheet"
              class="mt-5 flex flex-col gap-3 sm:flex-row sm:items-end"
            >
              <div class="min-w-0 flex-1">
                <.input
                  field={@source_form[:source_id]}
                  type="select"
                  label="Ficha de rendimiento"
                  prompt="Seleccionar"
                  options={@performance_sheet_options}
                  required
                />
              </div>

              <.button variant="primary" phx-disable-with="Generando...">
                Generar copia historica
              </.button>
            </.form>

            <p
              :if={@can_manage_budget && @budget_editable && @performance_sheet_options == []}
              class="mt-4 text-sm text-warning"
            >
              Crea primero una ficha en la biblioteca de rendimientos.
            </p>
          </div>

          <div :if={@budgeted_sheet} class="py-6">
            <div class="flex flex-wrap items-start justify-between gap-3">
              <div>
                <h3 class="font-semibold">{@budgeted_sheet.name}</h3>

                <p class="mt-1 text-sm text-base-content/60">
                  Copia de {@budgeted_sheet.source_performance_sheet.name}
                </p>
              </div>
              <span class="badge badge-outline">por {@budgeted_sheet.unit}</span>
            </div>

            <p class="mt-4 text-sm leading-6 text-base-content/65">
              {@budgeted_sheet.description}
            </p>

            <div :if={!@can_manage_budget || !@budget_editable} class="mt-6 overflow-x-auto">
              <.resource_table resources={@budgeted_sheet.resources} />
            </div>

            <p :if={@can_manage_budget && !@budget_editable} class="mt-4 text-sm text-success">
              Esta ficha forma parte de un presupuesto aprobado y no admite edicion directa.
            </p>

            <.form
              :if={@can_manage_budget && @budget_editable}
              for={@budgeted_sheet_form}
              id="budgeted-sheet-form"
              phx-submit="update_budgeted_sheet"
              class="mt-6 space-y-4"
            >
              <.input field={@budgeted_sheet_form[:name]} label="Nombre presupuestado" required />
              <.input
                field={@budgeted_sheet_form[:description]}
                type="textarea"
                label="Descripcion presupuestada"
                rows="3"
                required
              />
              <div class="grid gap-3 sm:grid-cols-3">
                <.input field={@budgeted_sheet_form[:unit]} label="Unidad" required />
                <.input
                  field={@budgeted_sheet_form[:productivity]}
                  type="number"
                  label="Productividad diaria"
                  min="0.0001"
                  step="0.0001"
                />
                <.input
                  field={@budgeted_sheet_form[:waste_percentage]}
                  type="number"
                  label="Desperdicio (%)"
                  min="0"
                  max="100"
                  step="0.0001"
                />
              </div>

              <fieldset class="space-y-4 border-t border-base-300 pt-4">
                <legend class="text-sm font-semibold">Recursos copiados</legend>

                <.inputs_for :let={resource_form} field={@budgeted_sheet_form[:resources]}>
                  <div class="grid gap-3 rounded-box border border-base-300 p-3 sm:grid-cols-4">
                    <.input
                      field={resource_form[:category]}
                      type="select"
                      label="Tipo"
                      options={resource_category_options()}
                      required
                    /> <.input field={resource_form[:name]} label="Recurso" required />
                    <.input field={resource_form[:unit]} label="Unidad" required />
                    <.input
                      field={resource_form[:quantity]}
                      type="number"
                      label="Cantidad"
                      min="0.0001"
                      step="0.0001"
                      required
                    />
                  </div>
                </.inputs_for>
              </fieldset>

              <.button variant="primary" phx-disable-with="Guardando...">
                Guardar ajustes
              </.button>
            </.form>
          </div>
        </section>
      </section>
    </Layouts.app>
    """
  end

  attr :resources, :list, required: true

  defp resource_table(assigns) do
    ~H"""
    <table class="table">
      <thead>
        <tr>
          <th>Tipo</th><th>Recurso</th><th class="text-right">Cantidad</th>
        </tr>
      </thead>

      <tbody>
        <tr :for={resource <- @resources}>
          <td>{Budget.resource_category_label(resource.category)}</td>

          <td>{resource.name}</td>

          <td class="text-right">{resource.quantity} {resource.unit}</td>
        </tr>
      </tbody>
    </table>
    """
  end

  @impl true
  def handle_event("validate_activity", %{"work_activity" => params}, socket) do
    changeset =
      %WorkActivity{}
      |> Execution.change_work_activity(
        params
        |> Map.put("project_id", socket.assigns.project.id)
        |> Map.put("work_item_id", socket.assigns.work_item.id)
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_activity_form(socket, changeset)}
  end

  def handle_event("save_activity", %{"work_activity" => params}, socket) do
    case Execution.create_work_activity(
           socket.assigns.current_scope,
           socket.assigns.project,
           socket.assigns.work_item,
           params
         ) do
      {:ok, activity} ->
        {:noreply,
         socket
         |> update(:activities, &(&1 ++ [activity]))
         |> assign_activity_form(Execution.change_work_activity(%WorkActivity{}))
         |> put_flash(:info, "Actividad de obra agregada correctamente.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_activity_form(socket, changeset)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "No tienes permiso para agregar actividades.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "No se pudo agregar la actividad.")}
    end
  end

  def handle_event(
        "create_budgeted_sheet",
        %{"budgeted_sheet_source" => %{"source_id" => source_id}},
        socket
      ) do
    case Budget.create_budgeted_performance_sheet(
           socket.assigns.current_scope,
           socket.assigns.project,
           socket.assigns.work_item,
           source_id
         ) do
      {:ok, sheet} ->
        {:noreply,
         socket
         |> assign(:budgeted_sheet, sheet)
         |> assign_budgeted_sheet_form(sheet)
         |> put_flash(:info, "Ficha presupuestada creada correctamente.")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "La partida ya tiene una ficha presupuestada.")}

      {:error, :budget_approved} ->
        {:noreply,
         put_flash(socket, :error, "El presupuesto aprobado no admite cambios directos.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "No se pudo generar la ficha presupuestada.")}
    end
  end

  def handle_event(
        "update_budgeted_sheet",
        %{"budgeted_performance_sheet" => params},
        socket
      ) do
    case Budget.update_budgeted_performance_sheet(
           socket.assigns.current_scope,
           socket.assigns.project,
           socket.assigns.budgeted_sheet,
           params
         ) do
      {:ok, sheet} ->
        {:noreply,
         socket
         |> assign(:budgeted_sheet, sheet)
         |> assign_budgeted_sheet_form(sheet)
         |> put_flash(:info, "Ficha presupuestada actualizada correctamente.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_budgeted_sheet_form(socket, changeset)}

      {:error, :budget_approved} ->
        {:noreply,
         put_flash(socket, :error, "El presupuesto aprobado no admite cambios directos.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "No se pudo actualizar la ficha presupuestada.")}
    end
  end

  defp performance_sheet_options(socket) do
    socket.assigns.current_scope
    |> Budget.list_performance_sheets()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp resource_category_options do
    Enum.map(Budget.resource_categories(), &{Budget.resource_category_label(&1), &1})
  end

  defp assign_source_form(socket) do
    assign(socket, :source_form, to_form(%{"source_id" => ""}, as: :budgeted_sheet_source))
  end

  defp assign_activity_form(socket, changeset) do
    assign(socket, :activity_form, to_form(changeset))
  end

  defp assign_budgeted_sheet_form(socket, nil) do
    assign(socket, :budgeted_sheet_form, nil)
  end

  defp assign_budgeted_sheet_form(socket, %BudgetedPerformanceSheet{} = sheet) do
    assign(socket, :budgeted_sheet_form, to_form(Budget.change_budgeted_performance_sheet(sheet)))
  end

  defp assign_budgeted_sheet_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :budgeted_sheet_form, to_form(changeset))
  end
end
