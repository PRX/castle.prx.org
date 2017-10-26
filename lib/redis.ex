defmodule Castle.Redis do
  @typedoc """
  A response + metadata tuple.
  """
  @type result :: {%{} | [%{}], %{}}

  @typedoc """
  A result prefixed with a datetime
  """
  @type dated_result :: {%DateTime{}, %{} | [%{}], %{}}

  @typedoc """
  The worker function for a partition, called with the datetime returned by the
  previous partition, and returning the datetime for the next partition to
  start on.
  """
  @type partition_worker :: (date :: %DateTime{} -> dated_result)

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
  Cache a list of intervals for a time range. The worker function will be called
  with a different from-dtim if there were any cache hits.
  """
  @callback interval(
    key_prefix :: String.t,
    intv       :: interval,
    identifier :: String.t,
    work_fn    :: (new_from :: %DateTime{} -> result)
  ) :: result

  @doc """
  Cache multiple partitions, passing the start-date of the next partition to
  the next worker function.
  """
  @callback partition(
    key_prefix :: String.t,
    worker_fns :: [partition_worker]
  ) :: result

  @doc """
  Cache multiple partitions with a custom function to combine result data.
  """
  @callback partition(
    key_prefix  :: String.t,
    combiner_fn :: (results :: [%{}] -> [%{}]),
    worker_fns  :: [partition_worker]
  ) :: result

  @doc """
  Get partition data only from redis - will return empty result on cache miss
  """
  @callback partition(
    key_prefix :: String.t,
    num_parts  :: pos_integer()
  ) :: result

  @doc """
  Get partition data with a custom combiner
  """
  @callback partition(
    key_prefix :: String.t,
    num_parts  :: pos_integer(),
    combiner_fn :: (results :: [%{}] -> [%{}])
  ) :: result
end
