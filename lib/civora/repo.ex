defmodule Civora.Repo do
  use Ecto.Repo,
    otp_app: :civora,
    adapter: Ecto.Adapters.Postgres
end
