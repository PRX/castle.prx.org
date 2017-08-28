defmodule Castle.Redis.Api do
  @behaviour Castle.Redis

  defdelegate cached(key, ttl, work_fn),
    to: Castle.Redis.ResponseCache,
    as: :cached

  defdelegate interval(key_prefix, intv, work_fn),
    to: Castle.Redis.IntervalCache,
    as: :interval

  defdelegate interval(key_prefix, from, to, interval, work_fn),
    to: Castle.Redis.IntervalCache,
    as: :interval

  defdelegate partition(key_prefix, worker_fns),
    to: Castle.Redis.PartitionCache,
    as: :partition

  defdelegate partition(key_prefix, combiner_fn, worker_fns),
    to: Castle.Redis.PartitionCache,
    as: :partition
end
