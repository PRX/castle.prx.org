defmodule BigQuery.TimestampRollup do
  @callback name() :: String.t
  @callback rollup() :: String.t
  @callback is_a?(String.t) :: boolean
  @callback floor(%DateTime{}) :: %DateTime{}
  @callback ceiling(%DateTime{}) :: %DateTime{}
  @callback range(%DateTime{}, %DateTime{}) :: [%DateTime{}]
  @callback count_range(%DateTime{}, %DateTime{}) :: pos_integer()
end
