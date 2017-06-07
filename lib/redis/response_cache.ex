defmodule Castle.Redis.ResponseCache do
  alias Castle.Redis.Conn, as: Conn

  def cached(key, val), do: cached(key, val, [])
  def cached(key, work_fn, opts) when is_function(work_fn) do
    case Conn.get(key, opts) do
      nil ->
        {val, meta} = work_fn.()
        Conn.set(key, val, opts)
        {val, meta}
      val ->
        {val, %{cached: true}}
    end
  end
  def cached(key, val, opts) do
    cached(key, fn() -> {val, %{cached: false}} end, opts)
  end
end
