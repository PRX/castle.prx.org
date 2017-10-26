defmodule Castle.FakeRedis do
  @behaviour Castle.Redis

  def cached(_key, _ttl, work_fn), do: work_fn.()

  def interval(_key_prefix, intv, ident, work_fn) do
    {data, meta} = work_fn.(intv)
    {Castle.Redis.IntervalCache.filter_work(data, ident), meta}
  end

  # TODO: these aren't as easy
  def partition(_key_prefix, _worker_fns), do: {[], %{fake: true}}
  def partition(_key_prefix, _combiner_fn, _worker_fns), do: {[], %{fake: true}}
  def partition_get(_key_prefix, _num_parts), do: {[], %{fake: true}}
  def partition_get(_key_prefix, _num_parts, _combiner_fn), do: {[], %{fake: true}}
end
