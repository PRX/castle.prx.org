defmodule Porter.Redis.CachedResponse do
  alias Porter.Redis.Conn, as: Conn

  def cached(key, ttl, work_fn) do
    case Conn.get(key) do
      nil ->
        {val, meta} = work_fn.()
        Conn.set(key, ttl, val)
        {val, meta}
      val ->
        {val, %{cached: true}}
    end
  end
end
