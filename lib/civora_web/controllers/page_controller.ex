defmodule CivoraWeb.PageController do
  use CivoraWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def health(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
