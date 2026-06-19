defmodule CivoraWeb.PageController do
  use CivoraWeb, :controller

  def health(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
