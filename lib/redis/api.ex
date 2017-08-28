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

  defdelegate partition(key, part_work_fns),
    to: Castle.Redis.PartitionCache,
    as: :partition

  defdelegate partition(key, combiner_fn, part_work_fns),
    to: Castle.Redis.PartitionCache,
    as: :partition
end
