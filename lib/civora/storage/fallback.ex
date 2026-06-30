defmodule Civora.Storage.Fallback do
  @moduledoc """
  Storage adapter that prefers R2 and falls back to local filesystem storage
  while R2 credentials are unavailable.
  """

  @behaviour Civora.Storage

  @impl true
  def put_object(key, body, opts \\ []) do
    case Civora.Storage.R2.put_object(key, body, opts) do
      {:error, {:not_configured, _variables}} -> Civora.Storage.Local.put_object(key, body, opts)
      result -> result
    end
  end

  @impl true
  def get_object(key) do
    case Civora.Storage.R2.get_object(key) do
      {:error, {:not_configured, _variables}} -> Civora.Storage.Local.get_object(key)
      result -> result
    end
  end
end
