defmodule BigQuery.TimestampRollups.Daily do
  @behaviour BigQuery.TimestampRollup

  def name, do: "DAY"

  def rollup, do: "TIMESTAMP_TRUNC(timestamp, DAY)"

  def is_a?(param), do: Enum.member?(["1d", "DAY"], param)

  def floor(time) do
    Timex.beginning_of_day(time)
  end

  def ceiling(time) do
    if Timex.compare(floor(time), time) == 0 do
      time
    else
      Timex.end_of_day(time) |> Timex.shift(microseconds: 1)
    end
  end

  def range(from, to, _inclusive_to=false) do
    range(floor(from), ceiling(to), [])
  end
  def range(from, to, _inclusive_to=true) do
    range(floor(from), ceiling(Timex.shift(to, seconds: 1)), [])
  end
  def range(from, to, acc) do
    if Timex.compare(from, to) >= 0 do
      acc
    else
      next_from = Timex.shift(from, seconds: 1) |> ceiling()
      range(next_from, to, acc ++ [from])
    end
  end

  def count_range(from, to) do
    start = floor(from) |> Timex.to_unix()
    stop = ceiling(to) |> Timex.to_unix()
    Float.ceil(max(stop - start, 0) / 86400) |> round
  end
end
