defmodule Civora.Storage.Local do
  @moduledoc """
  Local filesystem storage for evidence when R2 is not configured.
  """

  @behaviour Civora.Storage

  @impl true
  def put_object(key, body, _opts \\ []) when is_binary(key) and is_binary(body) do
    with {:ok, path} <- object_path(key),
         :ok <- File.mkdir_p(Path.dirname(path)) do
      File.write(path, body)
    end
  end

  @impl true
  def get_object(key) when is_binary(key) do
    with {:ok, path} <- object_path(key) do
      File.read(path)
    end
  end

  defp object_path(key) do
    root = storage_root()
    path = Path.expand(Path.join(root, key))

    if inside_storage_root?(path, root) do
      {:ok, path}
    else
      {:error, :invalid_key}
    end
  end

  defp storage_root do
    :civora
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:root, "priv/storage")
    |> Path.expand()
  end

  defp inside_storage_root?(path, root) do
    String.starts_with?(path, root <> "/") or String.starts_with?(path, root <> "\\")
  end
end
