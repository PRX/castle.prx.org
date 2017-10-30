defmodule Castle.Redis.Api do
  @behaviour Castle.Redis

  defdelegate cached(key, ttl, work_fn),
    to: Castle.Redis.ResponseCache,
    as: :cached

  defdelegate interval(key_prefix, intv, identifier, work_fn),
    to: Castle.Redis.IntervalCache,
    as: :interval

  defdelegate partition(key_prefix, worker_fns),
    to: Castle.Redis.PartitionCache,
    as: :partition

  defdelegate partition(key_prefix, combiner_fn, worker_fns),
    to: Castle.Redis.PartitionCache,
    as: :partition

  defdelegate partition_get(key_prefix, num_parts),
    to: Castle.Redis.PartitionCache,
    as: :partition_get

  defdelegate partition_get(key_prefix, num_parts, combiner_fn),
    to: Castle.Redis.PartitionCache,
    as: :partition_get
end
