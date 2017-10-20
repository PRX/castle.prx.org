defmodule BigQuery.TimestampRollups.QuarterHourly do
  @behaviour BigQuery.TimestampRollup

  def name, do: "15MIN"

  def rollup do
    "TIMESTAMP_SECONDS(UNIX_SECONDS(timestamp) - MOD(UNIX_SECONDS(timestamp), 900))"
  end

  def is_a?(param), do: Enum.member?(["15m", "15MIN"], param)

  def floor(time) do
    seconds = Timex.to_unix(time)
    Timex.from_unix(seconds - rem(seconds, 900))
  end

  def ceiling(time) do
    seconds = Timex.to_unix(time)
    Timex.from_unix(round(Float.ceil(seconds / 900) * 900))
  end

  def range(from, to) do
    range(floor(from), ceiling(to), [])
  end
  def range(from, to, acc) do
    if Timex.compare(from, to) >= 0 do
      acc
    else
      next_from = Timex.shift(from, minutes: 15)
      range(next_from, to, acc ++ [from])
    end
  end
end
