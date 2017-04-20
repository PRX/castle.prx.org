defmodule Castle.FakeRedis do
  @behaviour Castle.Redis

  def cached(_key, _ttl, work_fn), do: work_fn.()
  def interval(_key_prefix, from, _to, _interval, work_fn), do: work_fn.(from)
end
