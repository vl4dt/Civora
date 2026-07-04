defmodule CivoraWeb.Router do
  use CivoraWeb, :router

  import CivoraWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CivoraWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CivoraWeb do
    pipe_through :api

    get "/health", PageController, :health
  end

  # Other scopes may use custom stacks.
  # scope "/api", CivoraWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:civora, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CivoraWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", CivoraWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{CivoraWeb.UserAuth, :require_authenticated}] do
      live "/", ProjectLive.Index, :index
      live "/projects/new", ProjectLive.New, :new
      live "/projects/:id/audit", AuditLive.Index, :index
      live "/projects/:project_id/work-items", WorkItemLive.Index, :index
      live "/projects/:project_id/work-items/:id", WorkItemLive.Show, :show
      live "/projects/:project_id/budget", ProjectBudgetLive.Show, :show
      live "/projects/:project_id/costs", ProjectCostLive.Show, :show
      live "/projects/:project_id/report", ProjectReportLive.Show, :show
      live "/projects/:project_id/subcontracts", SubcontractLive.Index, :index
      live "/projects/:project_id/subcontracts/:id", SubcontractLive.Show, :show
      live "/performance-sheets", PerformanceSheetLive.Index, :index
      live "/performance-sheets/:id", PerformanceSheetLive.Show, :show
      live "/counterparties", CounterpartyLive.Index, :index
      live "/counterparties/:id", CounterpartyLive.Show, :show
      live "/projects/:id", ProjectLive.Show, :show
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", CivoraWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{CivoraWeb.UserAuth, :mount_current_scope}] do
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
