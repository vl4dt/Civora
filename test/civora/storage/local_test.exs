defmodule Civora.Storage.LocalTest do
  use ExUnit.Case, async: false

  alias Civora.Storage
  alias Civora.Storage.Local
  alias Civora.Storage.R2

  setup do
    previous_adapter = Application.get_env(:civora, :storage_adapter)
    previous_r2 = Application.get_env(:civora, R2)
    previous_local = Application.get_env(:civora, Local)
    root = Path.expand("tmp/local-storage-test-#{System.unique_integer([:positive])}")

    Application.delete_env(:civora, :storage_adapter)
    Application.put_env(:civora, R2, endpoint: nil)
    Application.put_env(:civora, Local, root: root)

    on_exit(fn ->
      File.rm_rf(root)
      restore_env(:storage_adapter, previous_adapter)
      restore_env(R2, previous_r2)
      restore_env(Local, previous_local)
    end)

    %{root: root}
  end

  test "default storage falls back to local files when R2 is not configured", %{root: root} do
    assert :ok =
             Storage.put_object("evidence/projects/1/photo.jpg", "jpeg bytes",
               content_type: "image/jpeg"
             )

    assert {:ok, "jpeg bytes"} = Storage.get_object("evidence/projects/1/photo.jpg")
    assert File.read!(Path.join(root, "evidence/projects/1/photo.jpg")) == "jpeg bytes"
  end

  test "local storage rejects keys outside the configured root" do
    assert {:error, :invalid_key} = Local.put_object("../outside.txt", "bad")
  end

  defp restore_env(key, nil), do: Application.delete_env(:civora, key)
  defp restore_env(key, value), do: Application.put_env(:civora, key, value)
end
