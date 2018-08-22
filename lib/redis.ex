defmodule Castle.Redis do
  @typedoc """
  A response object.
  """
  @type result :: {%{} | [%{}], %{}}

  @typedoc """
  A result prefixed with a datetime
  """
  @type dated_result :: {%DateTime{}, %{} | [%{}], %{}}

  @typedoc """
  An interval timeframe
  """
  @type interval :: %{from: %DateTime{}, to: %DateTime{}, seconds: pos_integer()}

  @typedoc """
  A cached result plus an updated interval that excludes the cached result
  """
  @type result_with_new_interval :: {dated_result, interval}

  @doc """
  Cache the results of a function call.
  """
  @callback cached(
    key     :: String.t,
    ttl     :: pos_integer(),
    work_fn :: (() -> result)
  ) :: result

  @doc """
  Get very-recent podcast download INCRs.
  """
  @callback podcast_increments(
    id   :: pos_integer,
    intv :: interval
  ) :: result_with_new_interval

  @doc """
  Cache podcast totals (including INCRs)
  """
  @callback podcast_totals_cache(
    id      :: pos_integer,
    work_fn :: (() -> result)
  ) :: result

  @doc """
  Get very-recent podcast download INCRs.
  """
  @callback episode_increments(
    guid :: String.t,
    intv :: interval
  ) :: result_with_new_interval

  @doc """
  Cache episode totals (including INCRs)
  """
  @callback episode_totals_cache(
    guid    :: String.t,
    work_fn :: (() -> result)
  ) :: result
end
