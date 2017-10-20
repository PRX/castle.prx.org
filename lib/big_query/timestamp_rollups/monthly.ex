defmodule BigQuery.TimestampRollups.Monthly do
  @behaviour BigQuery.TimestampRollup

  def name, do: "MONTH"

  def rollup, do: "TIMESTAMP_TRUNC(timestamp, MONTH)"

  def is_a?(param), do: Enum.member?(["1M", "MONTH"], param)

  def floor(time) do
    Timex.beginning_of_month(time)
  end

  def ceiling(time) do
    if Timex.compare(floor(time), time) == 0 do
      time
    else
      Timex.end_of_month(time) |> Timex.shift(microseconds: 1)
    end
  end

  def range(from, to) do
    range(floor(from), ceiling(to), [])
  end
  def range(from, to, acc) do
    if Timex.compare(from, to) >= 0 do
      acc
    else
      next_from = Timex.shift(from, seconds: 1) |> ceiling()
      range(next_from, to, acc ++ [from])
    end
  end
end
