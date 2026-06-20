defmodule CivoraWeb.CounterpartyLive.Show do
  use CivoraWeb, :live_view

  alias Civora.Subcontracts
  alias Civora.Subcontracts.Counterparty

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Subcontracts.get_counterparty(socket.assigns.current_scope, id) do
      {:ok, counterparty} ->
        {:ok,
         socket
         |> assign(:page_title, counterparty.name)
         |> assign(:counterparty, counterparty)}

      {:error, :not_found} ->
        raise Ecto.NoResultsError, queryable: Counterparty
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="max-w-4xl">
        <.link
          navigate={~p"/counterparties"}
          class="inline-flex items-center gap-2 text-sm text-base-content/65 hover:text-base-content"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Contrapartes
        </.link>
        <div class="mt-6 border-b border-base-300 pb-7">
          <p class="text-sm font-medium text-primary">Identidad externa</p>
          <h1 class="mt-2 text-3xl font-semibold">{@counterparty.name}</h1>
          <span class="badge badge-outline mt-4">{Subcontracts.counterparty_role_label(
            @counterparty.role
          )}</span>
        </div>

        <dl class="grid gap-6 border-b border-base-300 py-7 sm:grid-cols-2">
          <div>
            <dt class="text-sm text-base-content/60">Rol de contraparte</dt>
            <dd class="mt-1 text-lg font-semibold">
              {Subcontracts.counterparty_role_label(@counterparty.role)}
            </dd>
          </div>
          <div>
            <dt class="text-sm text-base-content/60">Contacto</dt>
            <dd class="mt-1 whitespace-pre-line text-base">
              {@counterparty.contact || "No registrado"}
            </dd>
          </div>
        </dl>
      </section>
    </Layouts.app>
    """
  end
end
