defmodule Civora.Storage.Test do
  @moduledoc false

  @behaviour Civora.Storage

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def reset! do
    Agent.update(__MODULE__, fn _objects -> %{} end)
  end

  def objects do
    Agent.get(__MODULE__, & &1)
  end

  @impl true
  def put_object(key, body, opts \\ []) when is_binary(key) and is_binary(body) do
    Agent.update(__MODULE__, &Map.put(&1, key, %{body: body, opts: opts}))
  end

  @impl true
  def get_object(key) when is_binary(key) do
    case Agent.get(__MODULE__, &Map.get(&1, key)) do
      %{body: body} -> {:ok, body}
      nil -> {:error, :not_found}
    end
  end
end
