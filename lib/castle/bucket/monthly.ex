defmodule Castle.Bucket.Monthly do
  @behaviour Castle.Bucket

  def name, do: "MONTH"

  def rollup, do: "month"

  def is_a?(param), do: Enum.member?(all_labels(), param)

  def listeners_labels do
    ["MONTH"]
  end

  def downloads_labels do
    ["1M", "MONTH"]
  end

  def all_labels do
    listeners_labels() ++ downloads_labels() |> Enum.uniq
  end

  def floor(time) do
    Timex.beginning_of_month(time)
  end

  def ceiling(time) do
    if Timex.compare(__MODULE__.floor(time), time) == 0 do
      time
    else
      Timex.beginning_of_month(time) |> Timex.shift(months: 1)
    end
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

  # this is an estimate, since days-per-month varies
  def count_range(from, to) do
    start = __MODULE__.floor(from) |> Timex.to_unix()
    stop = ceiling(to) |> Timex.to_unix()
    Float.ceil(max(stop - start, 0) / 2592000) |> round
  end
end
