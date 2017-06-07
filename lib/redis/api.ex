defmodule Castle.Redis.Api do
  @behaviour Castle.Redis

  defdelegate cached(key, val, opts \\ []),
    to: Castle.Redis.ResponseCache,
    as: :cached

  defdelegate interval(key_prefix, from, to, interval, work_fn),
    to: Castle.Redis.IntervalCache,
    as: :interval
end
