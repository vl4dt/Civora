defmodule CivoraWeb.CounterpartyLiveTest do
  use CivoraWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "creates, lists, and opens a counterparty", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/counterparties")
    assert html =~ "Sin contrapartes registradas"

    {:ok, show, detail} =
      view
      |> form("#counterparty-form",
        counterparty: %{
          name: "Instalaciones del Norte",
          role: "subcontratista",
          contact: "Mario Diaz, +504 9999-0000"
        }
      )
      |> render_submit()
      |> follow_redirect(conn)

    assert detail =~ "Contraparte creada correctamente."
    assert detail =~ "Instalaciones del Norte"
    assert detail =~ "Subcontratista"
    assert detail =~ "Mario Diaz, +504 9999-0000"
    assert has_element?(show, ~s|a[href="/counterparties"]|)

    {:ok, _index, index_html} = live(conn, ~p"/counterparties")
    assert index_html =~ "Instalaciones del Norte"
  end

  test "validates required fields", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/counterparties")

    html =
      view
      |> form("#counterparty-form", counterparty: %{name: "", role: "", contact: ""})
      |> render_change()

    assert html =~ "can&#39;t be blank"
  end

  test "requires authentication", %{conn: _conn} do
    assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(build_conn(), ~p"/counterparties")
  end
end
