defmodule CivoraWeb.PageControllerTest do
  use CivoraWeb.ConnCase

  import Civora.AccountsFixtures

  test "GET / redirects anonymous users to login", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/users/log-in"
  end

  test "GET / renders the internal dashboard for authenticated users", %{conn: conn} do
    conn = conn |> log_in_user(user_fixture()) |> get(~p"/")
    assert html_response(conn, 200) =~ "Proyectos"
  end

  test "GET /health", %{conn: conn} do
    conn = get(conn, ~p"/health")
    assert json_response(conn, 200) == %{"status" => "ok"}
  end
end
