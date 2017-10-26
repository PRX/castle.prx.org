defmodule Castle.Redis.Interval.Getter do
  alias Castle.Redis.Conn, as: Conn
  alias Castle.Redis.Interval.Keys, as: Keys

  @buffer_seconds 30

  def get(key_prefix, ident, from, to, rollup) do
    range = rollup.range(from, to, false)
    counts = Keys.keys(key_prefix, range) |> Conn.hget(ident)
    cache_hits(range, counts)
  end

  defp cache_hits(times, counts), do: cache_hits(times, counts, [])
  defp cache_hits([time | rest_times], [count | rest_counts], accumulator) do
    case cache_val(time, count) do
      nil -> {accumulator, time}
      val -> cache_hits(rest_times, rest_counts, accumulator ++ [val])
    end
  end
  defp cache_hits(_out_of_times, _out_of_counts, accumulator) do
    {accumulator, nil}
  end

  def cache_val(time, [true, nil]), do: %{time: time, count: 0}
  def cache_val(time, [true, val]), do: %{time: time, count: val}
  def cache_val(time, [false, _val]) do
    elapsed = Timex.to_unix(Timex.now) - Timex.to_unix(time)
    if elapsed > @buffer_seconds do
      nil # miss
    else
      %{time: time, count: 0}
    end
  end
end
