defmodule CivoraWeb.WorkItemLive.Show do
  use CivoraWeb, :live_view

  alias Civora.Budget
  alias Civora.Budget.{BudgetedPerformanceSheet, WorkItem}
  alias Civora.Evidence
  alias Civora.Evidence.EvidenceAttachment
  alias Civora.Execution
  alias Civora.Execution.{ExecutedProgressEntry, WorkActivity}
  alias Civora.Projects
  alias Civora.Quality
  alias Civora.Quality.NonConformity

  @impl true
  def mount(%{"project_id" => project_id, "id" => id}, _session, socket) do
    with {:ok, project} <- Projects.get_project(socket.assigns.current_scope, project_id),
         {:ok, item} <- Budget.get_work_item(socket.assigns.current_scope, project, id),
         {:ok, activities} <-
           Execution.list_work_item_activities(socket.assigns.current_scope, project, item),
         {:ok, executed_progress_entries} <-
           Execution.list_work_item_executed_progress(socket.assigns.current_scope, project, item),
         {:ok, quality_controls} <-
           Quality.list_work_item_quality_controls(socket.assigns.current_scope, project, item),
         {:ok, non_conformities} <-
           Quality.list_work_item_non_conformities(socket.assigns.current_scope, project, item),
         {:ok, evidence_attachments} <-
           Evidence.list_work_item_attachments(socket.assigns.current_scope, project, item),
         {:ok, payable_progress} <-
           Quality.get_work_item_payable_progress(socket.assigns.current_scope, project, item),
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
       |> assign(:executed_progress_entries, executed_progress_entries)
       |> assign(:quality_controls_by_entry_id, quality_controls_by_entry_id(quality_controls))
       |> assign(:non_conformities, non_conformities)
       |> assign(:evidence_attachments, evidence_attachments)
       |> assign(
         :evidence_attachments_by_parent,
         evidence_attachments_by_parent(evidence_attachments)
       )
       |> assign(:payable_progress, payable_progress)
       |> assign(
         :non_conformities_by_quality_control_id,
         non_conformities_by_quality_control_id(non_conformities)
       )
       |> assign(:budgeted_sheet, budgeted_sheet)
       |> assign(:budget_editable, Budget.budget_editable?(project))
       |> assign(:performance_sheet_options, performance_sheet_options(socket))
       |> assign(
         :can_manage_activities,
         Projects.authorized?(socket.assigns.current_scope, project, :manage_activities)
       )
       |> assign(
         :can_manage_quality,
         Projects.authorized?(socket.assigns.current_scope, project, :manage_quality)
       )
       |> assign(
         :can_manage_budget,
         Projects.authorized?(socket.assigns.current_scope, project, :manage_budget)
       )
       |> assign_activity_form(Execution.change_work_activity(%WorkActivity{}))
       |> assign_executed_progress_form(
         Execution.change_executed_progress(%ExecutedProgressEntry{})
       )
       |> assign_non_conformity_form(Quality.change_non_conformity(%NonConformity{}))
       |> assign_evidence_form()
       |> assign_source_form()
       |> assign_budgeted_sheet_form(budgeted_sheet)
       |> allow_upload(:evidence_file,
         accept: ~w(.jpg .jpeg .png .webp .pdf),
         max_entries: 1,
         max_file_size: 10_000_000
       )}
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

        <section class="border-b border-base-300 py-7" aria-label="Avance pagable">
          <div class="flex flex-wrap items-end justify-between gap-4">
            <div>
              <p class="text-sm font-medium text-primary">Calidad</p>

              <h2 class="mt-1 text-xl font-semibold">Avance pagable</h2>
            </div>

            <span class="badge badge-success badge-outline">
              Pagable: {@payable_progress.payable_quantity} {@work_item.unit}
            </span>
          </div>

          <dl class="mt-5 grid gap-4 sm:grid-cols-4">
            <div class="border-l-2 border-base-300 pl-4">
              <dt class="text-sm text-base-content/60">Ejecutado</dt>

              <dd class="mt-1 font-semibold">
                {@payable_progress.executed_quantity} {@work_item.unit}
              </dd>
            </div>

            <div class="border-l-2 border-success pl-4">
              <dt class="text-sm text-base-content/60">Aceptado</dt>

              <dd class="mt-1 font-semibold">
                {@payable_progress.accepted_quantity} {@work_item.unit}
              </dd>
            </div>

            <div class="border-l-2 border-warning pl-4">
              <dt class="text-sm text-base-content/60">Rechazado</dt>

              <dd class="mt-1 font-semibold">
                {@payable_progress.rejected_quantity} {@work_item.unit}
              </dd>
            </div>

            <div class="border-l-2 border-error pl-4">
              <dt class="text-sm text-base-content/60">No conformidad abierta</dt>

              <dd class="mt-1 font-semibold">
                {@payable_progress.open_non_conformity_quantity} {@work_item.unit}
              </dd>
            </div>
          </dl>
        </section>

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

              <div class="mt-8 border-t border-base-300 pt-6">
                <h3 class="text-base font-semibold">Avance ejecutado</h3>

                <p class="mt-2 text-sm text-base-content/65">
                  Cantidades reportadas fisicamente. No son pagables hasta pasar por calidad.
                </p>

                <div
                  :if={@executed_progress_entries == []}
                  id="executed-progress-empty"
                  class="mt-4 rounded-box border border-dashed border-base-300 p-4 text-sm text-base-content/60"
                >
                  Sin avance ejecutado registrado.
                </div>

                <div
                  :for={entry <- @executed_progress_entries}
                  id={"executed-progress-#{entry.id}"}
                  class="mt-4 rounded-box border border-base-300 p-4"
                >
                  <div class="flex flex-wrap items-start justify-between gap-3">
                    <div>
                      <p class="font-semibold">
                        {entry.quantity} {@work_item.unit} en {entry.location_sector}
                      </p>

                      <p class="mt-1 text-sm text-base-content/60">
                        {entry.work_activity.location_sector}
                      </p>
                    </div>
                     <span :if={!entry.payable} class="badge badge-outline">No pagable</span>
                    <span :if={entry.payable} class="badge badge-success badge-outline">
                      Pagable
                    </span>
                  </div>

                  <.evidence_panel
                    attachments={
                      evidence_for(@evidence_attachments_by_parent, :executed_progress, entry.id)
                    }
                    can_manage={@can_manage_quality}
                  />

                  <div
                    :if={quality_control_for(@quality_controls_by_entry_id, entry)}
                    class="mt-4 border-t border-base-300 pt-4 text-sm"
                  >
                    <% control = quality_control_for(@quality_controls_by_entry_id, entry) %>
                    <p class="font-medium">{quality_status_label(control.status)}</p>

                    <p class="mt-1 text-base-content/65">
                      Aceptado: {control.accepted_quantity} {@work_item.unit}. Rechazado: {control.rejected_quantity} {@work_item.unit}.
                    </p>

                    <p :if={control.rejection_reason} class="mt-1 text-base-content/65">
                      Motivo: {control.rejection_reason}
                    </p>

                    <span
                      :if={control.non_conformity_originated}
                      class="badge badge-warning badge-outline mt-3"
                    >
                      Origina no conformidad
                    </span>

                    <span
                      :if={
                        non_conformity_for_control(@non_conformities_by_quality_control_id, control)
                      }
                      class="badge badge-error badge-outline mt-3"
                    >
                      No conformidad registrada
                    </span>

                    <.evidence_panel
                      attachments={
                        evidence_for(@evidence_attachments_by_parent, :quality_control, control.id)
                      }
                      can_manage={@can_manage_quality}
                    />

                    <.form
                      :if={
                        @can_manage_quality &&
                          control.non_conformity_originated &&
                          Decimal.gt?(control.rejected_quantity, Decimal.new("0")) &&
                          is_nil(
                            non_conformity_for_control(
                              @non_conformities_by_quality_control_id,
                              control
                            )
                          )
                      }
                      for={non_conformity_form(control, entry)}
                      id={"non-conformity-from-quality-form-#{control.id}"}
                      phx-submit="save_non_conformity"
                      class="mt-4 grid gap-3 border-t border-base-300 pt-4 sm:grid-cols-2"
                    >
                      <input
                        type="hidden"
                        name="non_conformity[quality_control_id]"
                        value={control.id}
                      />
                      <.input
                        field={non_conformity_form(control, entry)[:defect]}
                        type="textarea"
                        label="Defecto"
                        rows="3"
                        required
                      />
                      <.input
                        field={non_conformity_form(control, entry)[:location_sector]}
                        label="Ubicacion"
                        required
                      />
                      <.input
                        field={non_conformity_form(control, entry)[:responsible_name]}
                        label="Responsable"
                        required
                      />
                      <.input
                        field={non_conformity_form(control, entry)[:due_on]}
                        type="date"
                        label="Fecha limite"
                      />
                      <div class="sm:col-span-2">
                        <.input
                          field={non_conformity_form(control, entry)[:disposition]}
                          type="textarea"
                          label="Disposicion"
                          rows="3"
                        />
                      </div>

                      <.button
                        variant="primary"
                        class="sm:col-span-2"
                        phx-disable-with="Registrando..."
                      >
                        Registrar no conformidad
                      </.button>
                    </.form>
                  </div>

                  <.form
                    :if={
                      @can_manage_quality &&
                        is_nil(quality_control_for(@quality_controls_by_entry_id, entry))
                    }
                    for={quality_control_form(entry)}
                    id={"quality-control-form-#{entry.id}"}
                    phx-submit="save_quality_control"
                    class="mt-4 grid gap-3 border-t border-base-300 pt-4 sm:grid-cols-2"
                  >
                    <input
                      type="hidden"
                      name="quality_control[executed_progress_entry_id]"
                      value={entry.id}
                    />
                    <.input
                      field={quality_control_form(entry)[:accepted_quantity]}
                      type="number"
                      label="Cantidad aceptada"
                      min="0"
                      max={Decimal.to_string(entry.quantity, :normal)}
                      step="0.0001"
                      required
                    />
                    <.input
                      field={quality_control_form(entry)[:non_conformity_originated]}
                      type="checkbox"
                      label="Origina no conformidad"
                    />
                    <div class="sm:col-span-2">
                      <.input
                        field={quality_control_form(entry)[:rejection_reason]}
                        type="textarea"
                        label="Motivo del rechazo parcial o total"
                        rows="3"
                      />
                    </div>

                    <.button variant="primary" class="sm:col-span-2" phx-disable-with="Registrando...">
                      Registrar control de calidad
                    </.button>
                  </.form>
                </div>
              </div>

              <div class="mt-8 border-t border-base-300 pt-6">
                <h3 class="text-base font-semibold">No conformidades</h3>

                <div
                  :if={@non_conformities == []}
                  id="non-conformities-empty"
                  class="mt-4 rounded-box border border-dashed border-base-300 p-4 text-sm text-base-content/60"
                >
                  Sin no conformidades registradas.
                </div>

                <div
                  :for={non_conformity <- @non_conformities}
                  id={"non-conformity-#{non_conformity.id}"}
                  class="mt-4 rounded-box border border-base-300 p-4"
                >
                  <div class="flex flex-wrap items-start justify-between gap-3">
                    <div>
                      <p class="font-semibold">{non_conformity.defect}</p>

                      <p class="mt-1 text-sm text-base-content/65">
                        {non_conformity.affected_quantity} {@work_item.unit} afectados en {non_conformity.location_sector}
                      </p>

                      <p class="mt-1 text-sm text-base-content/65">
                        Responsable: {non_conformity.responsible_name}
                      </p>

                      <p :if={non_conformity.disposition} class="mt-1 text-sm text-base-content/65">
                        Disposicion: {non_conformity.disposition}
                      </p>

                      <p :if={non_conformity.closure_notes} class="mt-1 text-sm text-base-content/65">
                        Cierre: {non_conformity.closure_notes}
                      </p>
                    </div>

                    <span :if={non_conformity.status == :open} class="badge badge-error badge-outline">
                      Abierta
                    </span>

                    <span
                      :if={non_conformity.status == :closed}
                      class="badge badge-success badge-outline"
                    >
                      Cerrada
                    </span>
                  </div>

                  <.evidence_panel
                    attachments={
                      evidence_for(
                        @evidence_attachments_by_parent,
                        :non_conformity,
                        non_conformity.id
                      )
                    }
                    can_manage={@can_manage_quality}
                  />

                  <.form
                    :if={@can_manage_quality && non_conformity.status == :open}
                    for={close_non_conformity_form(non_conformity)}
                    id={"close-non-conformity-form-#{non_conformity.id}"}
                    phx-submit="close_non_conformity"
                    class="mt-4 grid gap-3 border-t border-base-300 pt-4 sm:grid-cols-[minmax(0,1fr)_auto]"
                  >
                    <input
                      type="hidden"
                      name="non_conformity_close[id]"
                      value={non_conformity.id}
                    />
                    <.input
                      field={close_non_conformity_form(non_conformity)[:closure_notes]}
                      label="Notas de cierre"
                      required
                    />
                    <.button variant="primary" phx-disable-with="Cerrando...">
                      Cerrar
                    </.button>
                  </.form>
                </div>
              </div>
            </div>

            <aside :if={@can_manage_activities || @can_manage_quality}>
              <div :if={@can_manage_activities}>
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
              </div>

              <div :if={@can_manage_activities} class="mt-8 border-t border-base-300 pt-6">
                <h3 class="text-base font-semibold">Registrar avance</h3>

                <p :if={@activities == []} class="mt-4 text-sm leading-6 text-warning">
                  Crea primero una actividad para registrar avance ejecutado.
                </p>

                <.form
                  :if={@activities != []}
                  for={@executed_progress_form}
                  id="executed-progress-form"
                  phx-change="validate_executed_progress"
                  phx-submit="save_executed_progress"
                  class="mt-5 space-y-4"
                >
                  <.input
                    field={@executed_progress_form[:work_activity_id]}
                    type="select"
                    label="Actividad"
                    prompt="Seleccionar"
                    options={activity_options(@activities)}
                    required
                  />
                  <.input
                    field={@executed_progress_form[:quantity]}
                    type="number"
                    label="Cantidad ejecutada"
                    min="0.0001"
                    step="0.0001"
                    required
                  />
                  <.input
                    field={@executed_progress_form[:location_sector]}
                    label="Ubicacion reportada"
                    placeholder="Nivel 2 / fachada norte"
                    required
                  />
                  <.button variant="primary" class="w-full" phx-disable-with="Registrando...">
                    Registrar avance
                  </.button>
                </.form>
              </div>

              <div :if={@can_manage_quality} class="mt-8 border-t border-base-300 pt-6">
                <h3 class="text-base font-semibold">Adjuntar evidencia</h3>

                <p
                  :if={evidence_target_options(assigns) == []}
                  class="mt-4 text-sm leading-6 text-warning"
                >
                  Registra avance, control de calidad o no conformidad para adjuntar evidencia.
                </p>

                <.form
                  :if={evidence_target_options(assigns) != []}
                  for={@evidence_form}
                  id="evidence-form"
                  phx-submit="save_evidence"
                  class="mt-5 space-y-4"
                >
                  <.input
                    field={@evidence_form[:target]}
                    type="select"
                    label="Registro"
                    prompt="Seleccionar"
                    options={evidence_target_options(assigns)}
                    required
                  />

                  <.live_file_input
                    upload={@uploads.evidence_file}
                    class="file-input file-input-bordered w-full"
                  />

                  <p
                    :for={entry <- @uploads.evidence_file.entries}
                    class="text-sm text-base-content/65"
                  >
                    {entry.client_name}
                  </p>

                  <p
                    :for={error <- upload_errors(@uploads.evidence_file)}
                    class="text-sm text-error"
                  >
                    {upload_error_label(error)}
                  </p>

                  <.button variant="primary" class="w-full" phx-disable-with="Adjuntando...">
                    Adjuntar evidencia
                  </.button>
                </.form>
              </div>

              <div :if={@can_manage_quality} class="mt-8 border-t border-base-300 pt-6">
                <h3 class="text-base font-semibold">Registrar no conformidad</h3>

                <.form
                  for={@non_conformity_form}
                  id="non-conformity-form"
                  phx-change="validate_non_conformity"
                  phx-submit="save_non_conformity"
                  class="mt-5 space-y-4"
                >
                  <.input
                    field={@non_conformity_form[:defect]}
                    type="textarea"
                    label="Defecto"
                    rows="3"
                    required
                  />
                  <.input
                    field={@non_conformity_form[:location_sector]}
                    label="Ubicacion"
                    required
                  />
                  <.input
                    field={@non_conformity_form[:responsible_name]}
                    label="Responsable"
                    required
                  />
                  <.input
                    field={@non_conformity_form[:affected_quantity]}
                    type="number"
                    label="Cantidad afectada"
                    min="0.0001"
                    step="0.0001"
                    required
                  />
                  <.input
                    field={@non_conformity_form[:due_on]}
                    type="date"
                    label="Fecha limite"
                  />
                  <.input
                    field={@non_conformity_form[:disposition]}
                    type="textarea"
                    label="Disposicion"
                    rows="3"
                  />
                  <.button variant="primary" class="w-full" phx-disable-with="Registrando...">
                    Registrar no conformidad
                  </.button>
                </.form>
              </div>
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

  attr :attachments, :list, required: true
  attr :can_manage, :boolean, default: false

  defp evidence_panel(assigns) do
    ~H"""
    <div class="mt-4 border-t border-base-300 pt-4">
      <p class="text-sm font-semibold">Evidencia</p>

      <div :if={@attachments == []} class="mt-2 text-sm text-base-content/60">
        Sin evidencia adjunta.
      </div>

      <div
        :for={attachment <- @attachments}
        id={"evidence-attachment-#{attachment.id}"}
        class="mt-3 rounded-box border border-base-300 p-3 text-sm"
      >
        <div class="flex flex-wrap items-start justify-between gap-3">
          <div>
            <p class="font-medium">{attachment.original_filename}</p>
            <p class="mt-1 text-base-content/60">
              {attachment.content_type} - {format_bytes(attachment.byte_size)} - {attachment.uploaded_by.email} - {format_datetime(
                attachment.inserted_at
              )}
            </p>
            <p :if={attachment.status == :invalidated} class="mt-1 text-warning">
              Invalidada: {attachment.invalidation_reason}
            </p>
          </div>

          <span :if={attachment.status == :valid} class="badge badge-success badge-outline">
            Vigente
          </span>
          <span :if={attachment.status == :invalidated} class="badge badge-warning badge-outline">
            Invalidada
          </span>
        </div>

        <.form
          :if={@can_manage && attachment.status == :valid}
          for={invalidate_evidence_form(attachment)}
          id={"invalidate-evidence-form-#{attachment.id}"}
          phx-submit="invalidate_evidence"
          class="mt-3 grid gap-3 border-t border-base-300 pt-3 sm:grid-cols-[minmax(0,1fr)_auto]"
        >
          <input type="hidden" name="evidence_invalidation[id]" value={attachment.id} />
          <.input
            field={invalidate_evidence_form(attachment)[:invalidation_reason]}
            label="Motivo de invalidacion"
            required
          />
          <.button variant="primary" phx-disable-with="Invalidando...">
            Invalidar
          </.button>
        </.form>
      </div>
    </div>
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

  def handle_event("validate_executed_progress", %{"executed_progress" => params}, socket) do
    changeset =
      %ExecutedProgressEntry{}
      |> Execution.change_executed_progress(
        params
        |> Map.put("project_id", socket.assigns.project.id)
        |> Map.put("work_item_id", socket.assigns.work_item.id)
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_executed_progress_form(socket, changeset)}
  end

  def handle_event("save_executed_progress", %{"executed_progress" => params}, socket) do
    with %WorkActivity{} = activity <- selected_activity(socket.assigns.activities, params) do
      case Execution.create_executed_progress(
             socket.assigns.current_scope,
             socket.assigns.project,
             activity,
             params
           ) do
        {:ok, entry} ->
          {:noreply,
           socket
           |> update(:executed_progress_entries, &[entry | &1])
           |> assign_executed_progress_form(
             Execution.change_executed_progress(%ExecutedProgressEntry{})
           )
           |> assign_payable_progress()
           |> put_flash(:info, "Avance ejecutado registrado correctamente.")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_executed_progress_form(socket, changeset)}

        {:error, :unauthorized} ->
          {:noreply, put_flash(socket, :error, "No tienes permiso para registrar avance.")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "No se pudo registrar el avance.")}
      end
    else
      nil -> {:noreply, put_flash(socket, :error, "Selecciona una actividad valida.")}
    end
  end

  def handle_event("save_quality_control", %{"quality_control" => params}, socket) do
    with %ExecutedProgressEntry{} = entry <-
           selected_executed_progress(socket.assigns.executed_progress_entries, params) do
      case Quality.create_quality_control(
             socket.assigns.current_scope,
             socket.assigns.project,
             entry,
             params
           ) do
        {:ok, control} ->
          {:noreply,
           socket
           |> update(
             :quality_controls_by_entry_id,
             &Map.put(&1, control.executed_progress_entry_id, control)
           )
           |> update(:executed_progress_entries, &mark_entry_payable(&1, control))
           |> assign_payable_progress()
           |> put_flash(:info, "Control de calidad registrado correctamente.")}

        {:error, %Ecto.Changeset{}} ->
          {:noreply, put_flash(socket, :error, "Revisa la cantidad aceptada y el motivo.")}

        {:error, :accepted_quantity_exceeds_executed} ->
          {:noreply,
           put_flash(socket, :error, "La cantidad aceptada no puede superar el avance ejecutado.")}

        {:error, :unauthorized} ->
          {:noreply, put_flash(socket, :error, "No tienes permiso para controlar calidad.")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "No se pudo registrar el control de calidad.")}
      end
    else
      nil -> {:noreply, put_flash(socket, :error, "Selecciona un avance ejecutado valido.")}
    end
  end

  def handle_event("validate_non_conformity", %{"non_conformity" => params}, socket) do
    changeset =
      %NonConformity{}
      |> Quality.change_non_conformity(
        params
        |> Map.put("project_id", socket.assigns.project.id)
        |> Map.put("work_item_id", socket.assigns.work_item.id)
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_non_conformity_form(socket, changeset)}
  end

  def handle_event("save_non_conformity", %{"non_conformity" => params}, socket) do
    case Quality.create_non_conformity(
           socket.assigns.current_scope,
           socket.assigns.project,
           socket.assigns.work_item,
           params
         ) do
      {:ok, non_conformity} ->
        {:noreply,
         socket
         |> update(:non_conformities, &[non_conformity | &1])
         |> update(
           :non_conformities_by_quality_control_id,
           &put_non_conformity_by_quality_control_id(&1, non_conformity)
         )
         |> assign_non_conformity_form(Quality.change_non_conformity(%NonConformity{}))
         |> assign_payable_progress()
         |> put_flash(:info, "No conformidad registrada correctamente.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_non_conformity_form(socket, changeset)}

      {:error, :quality_control_without_rejection} ->
        {:noreply,
         put_flash(socket, :error, "El control de calidad no tiene cantidad rechazada.")}

      {:error, :unauthorized} ->
        {:noreply,
         put_flash(socket, :error, "No tienes permiso para registrar no conformidades.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "No se pudo registrar la no conformidad.")}
    end
  end

  def handle_event("close_non_conformity", %{"non_conformity_close" => params}, socket) do
    with %NonConformity{} = non_conformity <-
           selected_non_conformity(socket.assigns.non_conformities, params) do
      case Quality.close_non_conformity(
             socket.assigns.current_scope,
             socket.assigns.project,
             non_conformity,
             params
           ) do
        {:ok, closed_non_conformity} ->
          {:noreply,
           socket
           |> update(:non_conformities, &replace_non_conformity(&1, closed_non_conformity))
           |> update(
             :non_conformities_by_quality_control_id,
             &put_non_conformity_by_quality_control_id(&1, closed_non_conformity)
           )
           |> assign_payable_progress()
           |> put_flash(:info, "No conformidad cerrada correctamente.")}

        {:error, %Ecto.Changeset{}} ->
          {:noreply, put_flash(socket, :error, "Agrega notas de cierre validas.")}

        {:error, :already_closed} ->
          {:noreply, put_flash(socket, :error, "La no conformidad ya esta cerrada.")}

        {:error, :unauthorized} ->
          {:noreply, put_flash(socket, :error, "No tienes permiso para cerrar no conformidades.")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "No se pudo cerrar la no conformidad.")}
      end
    else
      nil -> {:noreply, put_flash(socket, :error, "Selecciona una no conformidad valida.")}
    end
  end

  def handle_event("save_evidence", %{"evidence" => %{"target" => target}}, socket) do
    with {:ok, parent_attrs} <- evidence_parent_attrs(target),
         [file_attrs] <- consume_evidence_upload(socket) do
      attrs = Map.merge(parent_attrs, file_attrs)

      case Evidence.create_attachment(
             socket.assigns.current_scope,
             socket.assigns.project,
             socket.assigns.work_item,
             attrs
           ) do
        {:ok, attachment} ->
          {:noreply,
           socket
           |> put_evidence_attachment(attachment)
           |> assign_evidence_form()
           |> put_flash(:info, "Evidencia adjuntada correctamente.")}

        {:error, {:not_configured, _variables}} ->
          {:noreply,
           put_flash(socket, :error, "El almacenamiento de evidencias no esta configurado.")}

        {:error, :unauthorized} ->
          {:noreply, put_flash(socket, :error, "No tienes permiso para adjuntar evidencia.")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "No se pudo adjuntar la evidencia.")}
      end
    else
      {:error, :invalid_target} ->
        {:noreply, put_flash(socket, :error, "Selecciona un registro valido.")}

      [] ->
        {:noreply, put_flash(socket, :error, "Selecciona un archivo para adjuntar.")}
    end
  end

  def handle_event("invalidate_evidence", %{"evidence_invalidation" => params}, socket) do
    with %EvidenceAttachment{} = attachment <-
           selected_evidence_attachment(socket.assigns.evidence_attachments, params) do
      case Evidence.invalidate_attachment(
             socket.assigns.current_scope,
             socket.assigns.project,
             attachment,
             params
           ) do
        {:ok, invalidated_attachment} ->
          {:noreply,
           socket
           |> replace_evidence_attachment(invalidated_attachment)
           |> put_flash(:info, "Evidencia invalidada correctamente.")}

        {:error, %Ecto.Changeset{}} ->
          {:noreply, put_flash(socket, :error, "Agrega un motivo valido para invalidar.")}

        {:error, :already_invalidated} ->
          {:noreply, put_flash(socket, :error, "La evidencia ya fue invalidada.")}

        {:error, :unauthorized} ->
          {:noreply, put_flash(socket, :error, "No tienes permiso para invalidar evidencia.")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "No se pudo invalidar la evidencia.")}
      end
    else
      nil -> {:noreply, put_flash(socket, :error, "Selecciona una evidencia valida.")}
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

  defp activity_options(activities) do
    Enum.map(activities, &{&1.location_sector, &1.id})
  end

  defp selected_activity(activities, %{"work_activity_id" => activity_id}) do
    Enum.find(activities, &(to_string(&1.id) == to_string(activity_id)))
  end

  defp selected_activity(_activities, _params), do: nil

  defp selected_executed_progress(entries, %{"executed_progress_entry_id" => entry_id}) do
    Enum.find(entries, &(to_string(&1.id) == to_string(entry_id)))
  end

  defp selected_executed_progress(_entries, _params), do: nil

  defp evidence_parent_attrs("executed_progress:" <> id),
    do: {:ok, %{"executed_progress_entry_id" => id}}

  defp evidence_parent_attrs("quality_control:" <> id), do: {:ok, %{"quality_control_id" => id}}
  defp evidence_parent_attrs("non_conformity:" <> id), do: {:ok, %{"non_conformity_id" => id}}
  defp evidence_parent_attrs(_target), do: {:error, :invalid_target}

  defp consume_evidence_upload(socket) do
    consume_uploaded_entries(socket, :evidence_file, fn %{path: path}, entry ->
      {:ok,
       %{
         "body" => File.read!(path),
         "original_filename" => entry.client_name,
         "content_type" => entry.client_type || "application/octet-stream",
         "byte_size" => entry.client_size
       }}
    end)
  end

  defp quality_controls_by_entry_id(controls) do
    Map.new(controls, &{&1.executed_progress_entry_id, &1})
  end

  defp quality_control_for(controls_by_entry_id, entry) do
    Map.get(controls_by_entry_id, entry.id)
  end

  defp non_conformities_by_quality_control_id(non_conformities) do
    non_conformities
    |> Enum.reject(&is_nil(&1.quality_control_id))
    |> Map.new(&{&1.quality_control_id, &1})
  end

  defp non_conformity_for_control(non_conformities_by_quality_control_id, control) do
    Map.get(non_conformities_by_quality_control_id, control.id)
  end

  defp put_non_conformity_by_quality_control_id(map, %NonConformity{
         quality_control_id: nil
       }) do
    map
  end

  defp put_non_conformity_by_quality_control_id(map, non_conformity) do
    Map.put(map, non_conformity.quality_control_id, non_conformity)
  end

  defp quality_control_form(entry) do
    to_form(
      %{
        "executed_progress_entry_id" => entry.id,
        "accepted_quantity" => Decimal.to_string(entry.quantity, :normal),
        "rejection_reason" => "",
        "non_conformity_originated" => false
      },
      as: :quality_control
    )
  end

  defp quality_status_label(:accepted), do: "Aceptado por calidad"
  defp quality_status_label(:partially_accepted), do: "Aceptado parcialmente"
  defp quality_status_label(:rejected), do: "Rechazado por calidad"

  defp non_conformity_form(control, entry) do
    to_form(
      %{
        "quality_control_id" => control.id,
        "defect" => control.rejection_reason || "",
        "location_sector" => entry.location_sector,
        "responsible_name" => "",
        "due_on" => "",
        "disposition" => ""
      },
      as: :non_conformity,
      id: "non_conformity_quality_#{control.id}"
    )
  end

  defp close_non_conformity_form(non_conformity) do
    to_form(
      %{
        "id" => non_conformity.id,
        "closure_notes" => ""
      },
      as: :non_conformity_close,
      id: "non_conformity_close_#{non_conformity.id}"
    )
  end

  defp selected_non_conformity(non_conformities, %{"id" => id}) do
    Enum.find(non_conformities, &(to_string(&1.id) == to_string(id)))
  end

  defp selected_non_conformity(_non_conformities, _params), do: nil

  defp selected_evidence_attachment(attachments, %{"id" => id}) do
    Enum.find(attachments, &(to_string(&1.id) == to_string(id)))
  end

  defp selected_evidence_attachment(_attachments, _params), do: nil

  defp replace_non_conformity(non_conformities, closed_non_conformity) do
    Enum.map(non_conformities, fn
      %NonConformity{id: id} when id == closed_non_conformity.id -> closed_non_conformity
      non_conformity -> non_conformity
    end)
  end

  defp evidence_attachments_by_parent(attachments) do
    Enum.group_by(attachments, &evidence_parent_key/1)
  end

  defp evidence_for(attachments_by_parent, parent_type, parent_id) do
    Map.get(attachments_by_parent, {parent_type, parent_id}, [])
  end

  defp evidence_parent_key(%EvidenceAttachment{executed_progress_entry_id: id})
       when not is_nil(id),
       do: {:executed_progress, id}

  defp evidence_parent_key(%EvidenceAttachment{quality_control_id: id}) when not is_nil(id),
    do: {:quality_control, id}

  defp evidence_parent_key(%EvidenceAttachment{non_conformity_id: id}) when not is_nil(id),
    do: {:non_conformity, id}

  defp put_evidence_attachment(socket, attachment) do
    attachments = [attachment | socket.assigns.evidence_attachments]

    socket
    |> assign(:evidence_attachments, attachments)
    |> assign(:evidence_attachments_by_parent, evidence_attachments_by_parent(attachments))
  end

  defp replace_evidence_attachment(socket, updated_attachment) do
    attachments =
      Enum.map(socket.assigns.evidence_attachments, fn
        %EvidenceAttachment{id: id} when id == updated_attachment.id -> updated_attachment
        attachment -> attachment
      end)

    socket
    |> assign(:evidence_attachments, attachments)
    |> assign(:evidence_attachments_by_parent, evidence_attachments_by_parent(attachments))
  end

  defp evidence_target_options(assigns) do
    progress_options =
      Enum.map(assigns.executed_progress_entries, fn entry ->
        {"Avance #{entry.id} - #{entry.quantity} #{assigns.work_item.unit} en #{entry.location_sector}",
         "executed_progress:#{entry.id}"}
      end)

    quality_options =
      assigns.quality_controls_by_entry_id
      |> Map.values()
      |> Enum.map(fn control ->
        {"Control de calidad #{control.id} - #{quality_status_label(control.status)}",
         "quality_control:#{control.id}"}
      end)

    non_conformity_options =
      Enum.map(assigns.non_conformities, fn non_conformity ->
        {"No conformidad #{non_conformity.id} - #{non_conformity.defect}",
         "non_conformity:#{non_conformity.id}"}
      end)

    progress_options ++ quality_options ++ non_conformity_options
  end

  defp invalidate_evidence_form(attachment) do
    to_form(
      %{
        "id" => attachment.id,
        "invalidation_reason" => ""
      },
      as: :evidence_invalidation,
      id: "evidence_invalidation_#{attachment.id}"
    )
  end

  defp mark_entry_payable(entries, control) do
    payable = Decimal.gt?(control.accepted_quantity, Decimal.new("0"))

    Enum.map(entries, fn
      %ExecutedProgressEntry{id: id} = entry when id == control.executed_progress_entry_id ->
        %{entry | payable: payable}

      entry ->
        entry
    end)
  end

  defp assign_source_form(socket) do
    assign(socket, :source_form, to_form(%{"source_id" => ""}, as: :budgeted_sheet_source))
  end

  defp assign_activity_form(socket, changeset) do
    assign(socket, :activity_form, to_form(changeset))
  end

  defp assign_executed_progress_form(socket, changeset) do
    assign(socket, :executed_progress_form, to_form(changeset, as: :executed_progress))
  end

  defp assign_non_conformity_form(socket, changeset) do
    assign(socket, :non_conformity_form, to_form(changeset))
  end

  defp assign_evidence_form(socket) do
    assign(socket, :evidence_form, to_form(%{"target" => ""}, as: :evidence))
  end

  defp assign_payable_progress(socket) do
    case Quality.get_work_item_payable_progress(
           socket.assigns.current_scope,
           socket.assigns.project,
           socket.assigns.work_item
         ) do
      {:ok, payable_progress} -> assign(socket, :payable_progress, payable_progress)
      {:error, _reason} -> socket
    end
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

  defp upload_error_label(:too_large), do: "El archivo supera el limite de 10 MB."
  defp upload_error_label(:too_many_files), do: "Adjunta un archivo a la vez."
  defp upload_error_label(:not_accepted), do: "Formato no permitido."
  defp upload_error_label(_error), do: "No se pudo adjuntar el archivo."

  defp format_bytes(bytes) when is_integer(bytes) and bytes >= 1_000_000 do
    "#{Float.round(bytes / 1_000_000, 1)} MB"
  end

  defp format_bytes(bytes) when is_integer(bytes) and bytes >= 1_000 do
    "#{Float.round(bytes / 1_000, 1)} KB"
  end

  defp format_bytes(bytes), do: "#{bytes} B"

  defp format_datetime(nil), do: ""

  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end
end
