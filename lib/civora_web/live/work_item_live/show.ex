defmodule CivoraWeb.WorkItemLive.Show do
  use CivoraWeb, :live_view

  alias Civora.Budget
  alias Civora.Budget.WorkItem
  alias Civora.Projects

  @impl true
  def mount(%{"project_id" => project_id, "id" => id}, _session, socket) do
    with {:ok, project} <- Projects.get_project(socket.assigns.current_scope, project_id),
         {:ok, item} <- Budget.get_work_item(socket.assigns.current_scope, project, id) do
      {:ok,
       socket
       |> assign(:page_title, item.description)
       |> assign(:project, project)
       |> assign(:work_item, item)}
    else
      {:error, _reason} -> raise Ecto.NoResultsError, queryable: WorkItem
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="max-w-3xl">
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
      </section>
    </Layouts.app>
    """
  end
end
