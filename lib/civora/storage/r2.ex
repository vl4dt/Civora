defmodule Civora.Storage.R2 do
  @moduledoc """
  Cloudflare R2 adapter using its S3-compatible API.
  """

  @behaviour Civora.Storage

  @required_config [:endpoint, :bucket, :access_key_id, :secret_access_key]

  @impl true
  def put_object(key, body, opts \\ []) when is_binary(key) and is_binary(body) do
    with {:ok, storage_config} <- storage_config() do
      put_options =
        case Keyword.get(opts, :content_type) do
          nil -> []
          content_type -> [content_type: content_type]
        end

      storage_config.bucket
      |> ExAws.S3.put_object(key, body, put_options)
      |> ExAws.request(storage_config.request_options)
      |> normalize_put_response()
    end
  end

  @impl true
  def get_object(key) when is_binary(key) do
    with {:ok, storage_config} <- storage_config() do
      storage_config.bucket
      |> ExAws.S3.get_object(key)
      |> ExAws.request(storage_config.request_options)
      |> normalize_get_response()
    end
  end

  defp storage_config do
    config = Application.get_env(:civora, __MODULE__, [])

    case Enum.filter(@required_config, &blank?(Keyword.get(config, &1))) do
      [] -> build_storage_config(config)
      missing -> {:error, {:not_configured, missing}}
    end
  end

  defp build_storage_config(config) do
    endpoint = Keyword.fetch!(config, :endpoint)
    uri = URI.parse(endpoint)

    if uri.scheme in ["http", "https"] and is_binary(uri.host) and
         uri.path in [nil, "", "/"] and is_nil(uri.userinfo) and is_nil(uri.query) and
         is_nil(uri.fragment) do
      {:ok,
       %{
         bucket: Keyword.fetch!(config, :bucket),
         request_options: [
           scheme: uri.scheme <> "://",
           host: uri.host,
           port: uri.port,
           region: "auto",
           access_key_id: Keyword.fetch!(config, :access_key_id),
           secret_access_key: Keyword.fetch!(config, :secret_access_key),
           virtual_host: false
         ]
       }}
    else
      {:error, {:invalid_endpoint, endpoint}}
    end
  end

  defp normalize_put_response({:ok, _response}), do: :ok
  defp normalize_put_response({:error, _reason} = error), do: error

  defp normalize_get_response({:ok, %{body: body}}), do: {:ok, body}
  defp normalize_get_response({:error, _reason} = error), do: error

  defp blank?(value), do: value in [nil, ""]
end
