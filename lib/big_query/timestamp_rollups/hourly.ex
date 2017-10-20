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

  def range(from, to) do
    range(floor(from), ceiling(to), [])
  end
  def range(from, to, acc) do
    if Timex.compare(from, to) >= 0 do
      acc
    else
      next_from = Timex.shift(from, hours: 1)
      range(next_from, to, acc ++ [from])
    end
  end
end
