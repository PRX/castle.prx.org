defmodule Castle.Bucket.Hourly do
  @behaviour Castle.Bucket

  def name, do: "HOUR"

  def rollup, do: "hour"

  def is_a?(param), do: Enum.member?(["1h", "HOUR"], param)

  def floor(time) do
    seconds = Timex.to_unix(time)
    Timex.from_unix(seconds - rem(seconds, 3600), :second)
  end

  def ceiling(time) do
    seconds = Timex.to_unix(time)
    Timex.from_unix(round(Float.ceil(seconds / 3600) * 3600), :second)
  end

  def next(time) do
    Timex.shift(time, seconds: 1) |> ceiling()
  end

  def range(from, to) do
    range(__MODULE__.floor(from), ceiling(to), [])
  end
  def range(from, to, acc) do
    if Timex.compare(from, to) >= 0 do
      acc
    else
      next(from) |> range(to, acc ++ [from])
    end
  end

  def count_range(from, to) do
    start = __MODULE__.floor(from) |> Timex.to_unix()
    stop = ceiling(to) |> Timex.to_unix()
    Float.ceil(max(stop - start, 0) / 3600) |> round
  end
end
