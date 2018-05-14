defmodule Castle do

  defmodule Interval do
    @enforce_keys [:from, :to, :bucket]
    defstruct [:from, :to, :bucket]
  end

  defmodule Bucket do
    @callback name() :: String.t
    @callback rollup() :: String.t
    @callback is_a?(String.t) :: boolean
    @callback floor(%DateTime{}) :: %DateTime{}
    @callback ceiling(%DateTime{}) :: %DateTime{}
    @callback next(%DateTime{}) :: %DateTime{}
    @callback range(%DateTime{}, %DateTime{}) :: [%DateTime{}]
    @callback count_range(%DateTime{}, %DateTime{}) :: pos_integer()
  end

end
