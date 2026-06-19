defmodule Civora.Storage.R2Test do
  use ExUnit.Case, async: false

  alias Civora.Storage.R2

  setup do
    bypass = Bypass.open()
    previous_config = Application.get_env(:civora, R2)

    Application.put_env(:civora, R2,
      endpoint: "http://localhost:#{bypass.port}",
      bucket: "civora-test",
      access_key_id: "test-access-key",
      secret_access_key: "test-secret-key"
    )

    on_exit(fn ->
      if previous_config do
        Application.put_env(:civora, R2, previous_config)
      else
        Application.delete_env(:civora, R2)
      end
    end)

    %{bypass: bypass}
  end

  test "uploads an object through a signed S3 request", %{bypass: bypass} do
    Bypass.expect_once(bypass, "PUT", "/civora-test/evidence/report.txt", fn conn ->
      assert ["text/plain"] = Plug.Conn.get_req_header(conn, "content-type")
      assert ["AWS4-HMAC-SHA256" <> _] = Plug.Conn.get_req_header(conn, "authorization")
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert body == "inspection complete"
      Plug.Conn.send_resp(conn, 200, "")
    end)

    assert :ok =
             R2.put_object("evidence/report.txt", "inspection complete",
               content_type: "text/plain"
             )
  end

  test "reads an object through a signed S3 request", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/civora-test/evidence/report.txt", fn conn ->
      assert ["AWS4-HMAC-SHA256" <> _] = Plug.Conn.get_req_header(conn, "authorization")
      Plug.Conn.send_resp(conn, 200, "inspection complete")
    end)

    assert {:ok, "inspection complete"} = R2.get_object("evidence/report.txt")
  end

  test "reports missing configuration without making a request" do
    Application.put_env(:civora, R2, endpoint: nil)

    assert {:error, {:not_configured, [:endpoint, :bucket, :access_key_id, :secret_access_key]}} =
             R2.get_object("evidence/report.txt")
  end

  test "rejects endpoints with paths" do
    Application.put_env(:civora, R2,
      endpoint: "https://example.com/not-an-s3-root",
      bucket: "civora-test",
      access_key_id: "test-access-key",
      secret_access_key: "test-secret-key"
    )

    assert {:error, {:invalid_endpoint, "https://example.com/not-an-s3-root"}} =
             R2.get_object("evidence/report.txt")
  end
end
