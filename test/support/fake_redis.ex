defmodule Castle.FakeRedis do
  @behaviour Castle.Redis

  def cached(_key, _ttl, work_fn), do: work_fn.()
  def interval(_key_prefix, from, _to, _interval, work_fn), do: work_fn.(from)
  def interval(_key_prefix, intv, work_fn), do: work_fn.(intv)

  # TODO: these aren't as easy
  def partition(_key_prefix, _worker_fns), do: {[], %{fake: true}}
  def partition(_key_prefix, _combiner_fn, _worker_fns), do: {[], %{fake: true}}
  def partition_get(_key_prefix, _num_parts), do: {[], %{fake: true}}
  def partition_get(_key_prefix, _num_parts, _combiner_fn), do: {[], %{fake: true}}
end
