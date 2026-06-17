defmodule CivoraWeb.PageController do
  use CivoraWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
