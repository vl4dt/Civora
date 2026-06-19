defmodule Civora.Storage do
  @moduledoc """
  Storage boundary for private evidence and document objects.
  """

  @callback put_object(String.t(), binary(), keyword()) :: :ok | {:error, term()}
  @callback get_object(String.t()) :: {:ok, binary()} | {:error, term()}

  def put_object(key, body, opts \\ []) do
    adapter().put_object(key, body, opts)
  end

  def get_object(key) do
    adapter().get_object(key)
  end

  defp adapter do
    Application.get_env(:civora, :storage_adapter, Civora.Storage.R2)
  end
end
