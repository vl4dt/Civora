defmodule CivoraWeb.UserLive.Login do
  use CivoraWeb, :live_view

  alias Civora.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md py-4 sm:py-10">
        <div class="border border-base-300 bg-base-100 p-6 sm:p-8">
          <.header>
            Iniciar sesion
            <:subtitle>
              <%= if @current_scope do %>
                Confirma tu identidad para continuar con esta accion.
              <% else %>
                Acceso interno de RS Ingenieria.
              <% end %>
            </:subtitle>
          </.header>

          <div :if={local_mail_adapter?()} class="alert alert-info mt-6">
            <.icon name="hero-information-circle" class="size-5 shrink-0" />
            <p>
              Correo local activo. Revisa <.link href="/dev/mailbox" class="underline">el buzon de desarrollo</.link>.
            </p>
          </div>

          <.form
            :let={f}
            for={@form}
            id="login_form_password"
            action={~p"/users/log-in"}
            phx-submit="submit_password"
            phx-trigger-action={@trigger_submit}
            class="mt-6 space-y-4"
          >
            <.input
              readonly={!!@current_scope}
              field={f[:email]}
              type="email"
              label="Correo electronico"
              autocomplete="username"
              spellcheck="false"
              required
              phx-mounted={JS.focus()}
            />
            <.input
              field={f[:password]}
              type="password"
              label="Contrasena"
              autocomplete="current-password"
              spellcheck="false"
              required
            />
            <.input field={f[:remember_me]} type="checkbox" label="Mantener sesion iniciada" />
            <.button class="btn btn-primary w-full">
              Iniciar sesion <.icon name="hero-arrow-right" class="size-4" />
            </.button>
          </.form>

          <div class="divider my-7 text-xs uppercase text-base-content/50">Recuperar acceso</div>

          <.form
            :let={f}
            for={@form}
            id="login_form_magic"
            action={~p"/users/log-in"}
            phx-submit="submit_magic"
            class="space-y-4"
          >
            <.input
              readonly={!!@current_scope}
              field={f[:email]}
              type="email"
              label="Correo electronico"
              autocomplete="username"
              spellcheck="false"
              required
            />
            <.button class="btn btn-outline w-full">
              Enviar enlace de acceso
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(user, &url(~p"/users/log-in/#{&1}"))
    end

    info =
      "Si el correo esta registrado, recibiras instrucciones para iniciar sesion en breve."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:civora, Civora.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
