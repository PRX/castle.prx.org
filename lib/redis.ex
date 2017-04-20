defmodule Castle.Redis do
  @typedoc """
  A response + metadata tuple.
  """
  @type result :: {%{} | [%{}], %{}}

  @doc """
  Cache the results of a function call.
  """
  @callback cached(key :: String.t, ttl :: pos_integer(), work_fn :: (() -> result)) :: result
  defdelegate cached(key, ttl, work_fn), to: Castle.Redis.ResponseCache,
    as: :cached

  @doc """
  Cache a list of intervals for a time range. The worker function will be called
  with a different from-dtim if there were any cache hits.
  """
  @callback interval(key_prefix :: String.t,
                     from       :: %DateTime{},
                     to         :: %DateTime{},
                     interval   :: pos_integer(),
                     work_fn    :: (new_from :: %DateTime{} -> result)
                    ) :: result
  defdelegate interval(key_prefix, from, to, interval, work_fn),
    to: Castle.Redis.IntervalCache,
    as: :interval
end
