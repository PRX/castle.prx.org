defmodule Castle.Redis do
  @typedoc """
  A response + metadata tuple.
  """
  @type result :: {%{} | [%{}], %{}}

  @typedoc """
  An interval timeframe
  """
  @type interval :: %{from: %DateTime{}, to: %DateTime{}, seconds: pos_integer()}

  @doc """
  Cache the results of a function call.
  """
  @callback cached(
    key     :: String.t,
    ttl     :: pos_integer(),
    work_fn :: (() -> result)
  ) :: result

  @doc """
  Cache intervals with a from/to/seconds object, instead of explicit params.
  """
  @callback interval(
    key_prefix :: String.t,
    intv       :: interval,
    work_fn    :: (new_from :: %DateTime{} -> result)
  ) :: result

  @doc """
  Cache a list of intervals for a time range. The worker function will be called
  with a different from-dtim if there were any cache hits.
  """
  @callback interval(
    key_prefix :: String.t,
    from       :: %DateTime{},
    to         :: %DateTime{},
    interval   :: pos_integer(),
    work_fn    :: (new_from :: %DateTime{} -> result)
  ) :: result
end
