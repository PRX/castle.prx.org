defmodule Castle.Redis.IntervalCache do
  alias Castle.Redis.Conn, as: Conn

  @past_interval_ttl 43200
  @current_interval_ttl 15
  @current_interval_buffer 3600

  def interval(key_prefix, from, to, interval, work_fn) do
    case interval_get(key_prefix, from, to, interval) do
      {[], _new_from} ->
        {data, meta} = work_fn.(from)
        interval_set(key_prefix, from, to, interval, Enum.map(data, &(&1.count)))
        {data, Map.put(meta, :cache_hits, 0)}
      {hits, nil} ->
        {hits, %{cached: true, cache_hits: length(hits)}}
      {hits, new_from} ->
        {data, meta} = work_fn.(new_from)
        interval_set(key_prefix, new_from, to, interval, Enum.map(data, &(&1.count)))
        {hits ++ data, Map.put(meta, :cache_hits, length(hits))}
    end
  end

  def interval_get(key_prefix, from, to, interval) do
    times = interval_times(from, to, interval)
    counts = interval_keys(key_prefix, from, to, interval) |> Conn.get()
    cache_hits(times, counts)
  end

  def interval_set(key_prefix, from, to, interval, counts) do
    Enum.zip([
      interval_keys(key_prefix, from, to, interval),
      interval_ttls(from, to, interval),
      counts,
    ]) |> Conn.set()
  end

  def interval_keys(prefix, from, to, interval) do
    interval_times(from, to, interval)
    |> Enum.map(&format/1)
    |> Enum.map(&("#{prefix}.#{interval}.#{&1}"))
  end

  def interval_ttls(from, to, interval) do
    now = Timex.now()
    Enum.map interval_times(from, to, interval), fn(dtim) ->
      interval_end = Timex.shift(dtim, seconds: interval + @current_interval_buffer)
      if Timex.compare(now, interval_end) < 0 do
        # IO.puts "CURRENT - #{now} #{interval_end}"
        @current_interval_ttl
      else
        # IO.puts "PAST - #{now} #{interval_end}"
        @past_interval_ttl
      end
    end
  end

  def interval_times(from, to, interval) do
    if Timex.compare(from, to) >= 0 do
      []
    else
      [from] ++ interval_times(Timex.shift(from, seconds: interval), to, interval)
    end
  end

  defp cache_hits(times, counts), do: cache_hits(times, counts, [])
  defp cache_hits([time | _times], [nil | _counts], accumulator), do: {accumulator, time}
  defp cache_hits([time | rest_times], [count | rest_counts], accumulator) do
    cache_hits rest_times, rest_counts, accumulator ++ [%{time: time, count: count}]
  end
  defp cache_hits(_out_of_times, _out_of_counts, accumulator), do: {accumulator, nil}

  defp format(dtim) do
    {:ok, formatted} = Timex.format(dtim, "{ISO:Extended:Z}")
    formatted
  end
end
