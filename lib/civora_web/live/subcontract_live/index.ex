defmodule CivoraWeb.SubcontractLive.Index do
  use CivoraWeb, :live_view

  alias Civora.Budget
  alias Civora.Projects
  alias Civora.Projects.Project
  alias Civora.Subcontracts
  alias Civora.Subcontracts.Subcontract

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    with {:ok, project} <- Projects.get_project(socket.assigns.current_scope, project_id),
         {:ok, work_items} <- Budget.list_work_items(socket.assigns.current_scope, project),
         {:ok, subcontracts} <-
           Subcontracts.list_subcontracts(socket.assigns.current_scope, project) do
      {:ok,
       socket
       |> assign(:page_title, "Subcontratos - #{project.name}")
       |> assign(:project, project)
       |> assign(:work_items, work_items)
       |> assign(
         :counterparties,
         Subcontracts.list_subcontractor_counterparties(socket.assigns.current_scope)
       )
       |> assign(:subcontracts, subcontracts)
       |> assign(
         :can_manage,
         Projects.authorized?(socket.assigns.current_scope, project, :manage_subcontracts)
       )
       |> assign(:supply_modality_options, supply_modality_options())
       |> assign_form(Subcontracts.change_subcontract(%Subcontract{}))}
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
          <p class="text-sm font-medium text-primary">Ejecucion contratada</p>
          <h1 class="mt-1 text-3xl font-semibold">Subcontratos</h1>
          <p class="mt-2 max-w-2xl text-sm text-base-content/65">
            Acuerdos de mano de obra vinculados a una o varias partidas del proyecto.
          </p>
        </div>
      </section>

      <section class="grid gap-8 py-4 lg:grid-cols-[minmax(0,1fr)_26rem]">
        <div aria-label="Subcontratos">
          <div
            :if={@subcontracts == []}
            id="subcontracts-empty"
            class="grid min-h-48 place-items-center border-b border-base-300 text-center"
          >
            <div>
              <.icon name="hero-document-text" class="mx-auto size-8 text-base-content/35" />
              <p class="mt-3 font-medium">Sin subcontratos registrados</p>
            </div>
          </div>

          <.link
            :for={subcontract <- @subcontracts}
            id={"subcontract-#{subcontract.id}"}
            navigate={~p"/projects/#{@project}/subcontracts/#{subcontract}"}
            class="block border-b border-base-300 py-5 hover:bg-base-200/40"
          >
            <div class="flex flex-wrap items-start justify-between gap-3">
              <div>
                <h2 class="font-semibold">{subcontract.name}</h2>
                <p class="mt-1 text-sm text-base-content/60">{subcontract.counterparty.name}</p>
              </div>
              <div class="text-right">
                <span class="badge badge-outline">
                  {Subcontracts.supply_modality_label(subcontract.supply_modality)}
                </span>
                <p class="mt-2 text-xs text-base-content/55">
                  {length(subcontract.work_items)} partidas
                </p>
              </div>
            </div>
          </.link>
        </div>

        <aside :if={@can_manage} class="border-l-0 border-base-300 lg:border-l lg:pl-8">
          <h2 class="text-base font-semibold">Nuevo subcontrato</h2>

          <p :if={@counterparties == []} class="mt-4 text-sm leading-6 text-warning">
            Registra una contraparte habilitada como subcontratista antes de continuar.
          </p>
          <p :if={@work_items == []} class="mt-4 text-sm leading-6 text-warning">
            Crea al menos una partida del proyecto antes de continuar.
          </p>

          <.form
            :if={@counterparties != [] && @work_items != []}
            for={@form}
            id="subcontract-form"
            phx-change="validate"
            phx-submit="save"
            class="mt-5 space-y-4"
          >
            <.input field={@form[:name]} label="Nombre" autocomplete="off" required />
            <.input
              field={@form[:counterparty_id]}
              type="select"
              label="Contraparte"
              prompt="Seleccionar"
              options={Enum.map(@counterparties, &{&1.name, &1.id})}
              required
            />
            <.input
              field={@form[:work_item_ids]}
              type="select"
              label="Partidas"
              options={Enum.map(@work_items, &{&1.description, &1.id})}
              multiple
              size="5"
              required
            />
            <p class="-mt-3 text-xs text-base-content/55">
              Usa Ctrl o Cmd para seleccionar varias partidas.
            </p>
            <.input
              field={@form[:supply_modality]}
              type="select"
              label="Modalidad de suministro"
              prompt="Seleccionar"
              options={@supply_modality_options}
              required
            />
            <.input
              field={@form[:current_contract_amount]}
              type="number"
              label="Monto contractual vigente"
              min="0.0001"
              step="0.0001"
              required
            />
            <div class="grid grid-cols-3 gap-3">
              <.input
                field={@form[:advance_percentage]}
                type="number"
                label="Anticipo (%)"
                min="0"
                max="100"
                step="0.0001"
                required
              />
              <.input
                field={@form[:retention_percentage]}
                type="number"
                label="Retencion (%)"
                min="0"
                max="100"
                step="0.0001"
                required
              />
              <.input
                field={@form[:amortization_percentage]}
                type="number"
                label="Amortizacion (%)"
                min="0"
                max="100"
                step="0.0001"
                required
              />
            </div>
            <.button variant="primary" class="btn btn-primary w-full" phx-disable-with="Creando...">
              <.icon name="hero-plus" class="size-4" /> Crear subcontrato
            </.button>
          </.form>
        </aside>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate", %{"subcontract" => params}, socket) do
    changeset =
      %Subcontract{}
      |> Subcontracts.change_subcontract(Map.put(params, "project_id", socket.assigns.project.id))
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"subcontract" => params}, socket) do
    case Subcontracts.create_subcontract(
           socket.assigns.current_scope,
           socket.assigns.project,
           params
         ) do
      {:ok, subcontract} ->
        {:noreply,
         socket
         |> put_flash(:info, "Subcontrato creado correctamente.")
         |> push_navigate(to: ~p"/projects/#{socket.assigns.project}/subcontracts/#{subcontract}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "No tienes permiso para crear subcontratos.")}
    end
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  defp supply_modality_options do
    Enum.map(Subcontracts.available_supply_modalities(), fn modality ->
      {Subcontracts.supply_modality_label(modality), modality}
    end)
  end
end
