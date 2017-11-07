defmodule BigQuery.TimestampRollups.Hourly do
  @behaviour BigQuery.TimestampRollup

  def name, do: "HOUR"

  def rollup, do: "TIMESTAMP_TRUNC(timestamp, HOUR)"

  def is_a?(param), do: Enum.member?(["1h", "HOUR"], param)

  def floor(time) do
    seconds = Timex.to_unix(time)
    Timex.from_unix(seconds - rem(seconds, 3600))
  end

  def ceiling(time) do
    seconds = Timex.to_unix(time)
    Timex.from_unix(round(Float.ceil(seconds / 3600) * 3600))
  end

  def next(time) do
    Timex.shift(time, seconds: 1) |> ceiling()
  end

  def range(from, to) do
    range(floor(from), next(to), [])
  end
  def range(from, to, acc) do
    if Timex.compare(from, to) >= 0 do
      acc
    else
      next_from = Timex.shift(from, hours: 1)
      range(next_from, to, acc ++ [from])
    end
  end

  def count_range(from, to) do
    start = floor(from) |> Timex.to_unix()
    stop = next(to) |> Timex.to_unix()
    Float.ceil(max(stop - start, 0) / 3600) |> round
  end
end
