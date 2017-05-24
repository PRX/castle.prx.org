defmodule PrxAuth.Certificate.Cache do
  use GenServer

  def cache_get(url) do
    case GenServer.call(__MODULE__, {:get, url}) do
      [{_url, expiration, data}] -> {:found, expiration, data}
      [] -> {:not_found}
    end
  end

  def cache_set(data, url, expiration) do
    GenServer.call(__MODULE__, {:set, url, expiration, data})
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_opts \\ []) do
    :ets.new(__MODULE__, [:set, :private, :named_table])
    {:ok, %{}}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, :ets.lookup(__MODULE__, key), state}
  end

  def handle_call({:set, key, expiration, data}, _from, state) do
    true = :ets.insert(__MODULE__, {key, expiration, data})
    {:reply, data, state}
  end
end
