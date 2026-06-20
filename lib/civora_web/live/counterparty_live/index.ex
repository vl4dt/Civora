defmodule CivoraWeb.CounterpartyLive.Index do
  use CivoraWeb, :live_view

  alias Civora.Subcontracts
  alias Civora.Subcontracts.Counterparty

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Contrapartes")
     |> assign(:counterparties, Subcontracts.list_counterparties(socket.assigns.current_scope))
     |> assign(:role_options, role_options())
     |> assign_form(Subcontracts.change_counterparty(%Counterparty{}))}
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
          <p class="text-sm font-medium text-primary">Subcontratos</p>
          <h1 class="mt-1 text-3xl font-semibold">Contrapartes</h1>
          <p class="mt-2 max-w-2xl text-sm text-base-content/65">
            Identidades externas que pueden participar como proveedores, subcontratistas o ambos.
          </p>
        </div>
      </section>

      <section class="grid gap-8 py-4 lg:grid-cols-[minmax(0,1fr)_24rem]">
        <div aria-label="Contrapartes">
          <div
            :if={@counterparties == []}
            id="counterparties-empty"
            class="grid min-h-48 place-items-center border-b border-base-300 text-center"
          >
            <div>
              <.icon name="hero-user-group" class="mx-auto size-8 text-base-content/35" />
              <p class="mt-3 font-medium">Sin contrapartes registradas</p>
            </div>
          </div>

          <.link
            :for={counterparty <- @counterparties}
            id={"counterparty-#{counterparty.id}"}
            navigate={~p"/counterparties/#{counterparty}"}
            class="block border-b border-base-300 py-5 hover:bg-base-200/40"
          >
            <div class="flex flex-wrap items-start justify-between gap-3">
              <div>
                <h2 class="font-semibold">{counterparty.name}</h2>
                <p class="mt-1 line-clamp-1 text-sm text-base-content/60">
                  {counterparty.contact || "Sin contacto registrado"}
                </p>
              </div>
              <span class="badge badge-outline">{Subcontracts.counterparty_role_label(
                counterparty.role
              )}</span>
            </div>
          </.link>
        </div>

        <aside class="border-l-0 border-base-300 lg:border-l lg:pl-8">
          <h2 class="text-base font-semibold">Nueva contraparte</h2>
          <.form
            for={@form}
            id="counterparty-form"
            phx-change="validate"
            phx-submit="save"
            class="mt-5 space-y-4"
          >
            <.input field={@form[:name]} label="Nombre" autocomplete="off" required />
            <.input
              field={@form[:role]}
              type="select"
              label="Rol"
              prompt="Seleccionar"
              options={@role_options}
              required
            />
            <.input
              field={@form[:contact]}
              type="textarea"
              label="Contacto (opcional)"
              rows="4"
              placeholder="Persona, telefono o correo"
            />
            <.button variant="primary" class="btn btn-primary w-full" phx-disable-with="Creando...">
              <.icon name="hero-plus" class="size-4" /> Crear contraparte
            </.button>
          </.form>
        </aside>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate", %{"counterparty" => params}, socket) do
    changeset =
      %Counterparty{}
      |> Subcontracts.change_counterparty(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"counterparty" => params}, socket) do
    case Subcontracts.create_counterparty(socket.assigns.current_scope, params) do
      {:ok, counterparty} ->
        {:noreply,
         socket
         |> put_flash(:info, "Contraparte creada correctamente.")
         |> push_navigate(to: ~p"/counterparties/#{counterparty}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  defp role_options do
    Enum.map(Subcontracts.available_counterparty_roles(), fn role ->
      {Subcontracts.counterparty_role_label(role), role}
    end)
  end
end
