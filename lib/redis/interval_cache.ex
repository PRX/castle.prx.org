defmodule Castle.Redis.IntervalCache do
  alias Castle.Redis.Conn, as: Conn

  @past_interval_ttl 2592000 # 30 days
  @current_interval_ttl 300
  @current_interval_buffer 3600

  def interval(key_prefix, interval, work_fn) do
    interval key_prefix, interval.from, interval.to, interval.rollup, fn(new_from) ->
      interval |> Map.put(:from, new_from) |> work_fn.()
    end
  end
  def interval(key_prefix, from, to, rollup, work_fn) do
    case interval_get(key_prefix, from, to, rollup) do
      {[], _new_from} ->
        {data, meta} = work_fn.(from) |> interval_fill_zeros(from, to, rollup)
        interval_set(key_prefix, from, to, rollup, Enum.map(data, &(&1.count)))
        {data, Map.put(meta, :cache_hits, 0)}
      {hits, nil} ->
        {hits, %{cached: true, cache_hits: length(hits)}}
      {hits, new_from} ->
        {data, meta} = work_fn.(new_from) |> interval_fill_zeros(new_from, to, rollup)
        interval_set(key_prefix, new_from, to, rollup, Enum.map(data, &(&1.count)))
        {hits ++ data, Map.put(meta, :cache_hits, length(hits))}
    end
  end

  def interval_get(key_prefix, from, to, rollup) do
    counts = interval_keys(key_prefix, from, to, rollup) |> Conn.get()
    cache_hits(rollup.range(from, to), counts)
  end

  def interval_set(_key_prefix, _from, _to, _rollup, []), do: []
  def interval_set(key_prefix, from, to, rollup, counts) do
    Enum.zip([
      interval_keys(key_prefix, from, to, rollup),
      interval_ttls(from, to, rollup),
      counts,
    ]) |> Conn.set()
  end

  def interval_keys(prefix, from, to, rollup) do
    rollup.range(from, to)
    |> Enum.map(&format/1)
    |> Enum.map(&("#{prefix}.#{rollup.name()}.#{&1}"))
  end

  def interval_ttls(from, to, rollup) do
    now = Timex.now() |> Timex.shift(seconds: -@current_interval_buffer)
    Enum.map rollup.range(from, to), fn(dtim) ->
      interval_end = rollup.ceiling(Timex.shift(dtim, seconds: 1))
      if Timex.compare(now, interval_end) < 0 do
        @current_interval_ttl
      else
        @past_interval_ttl
      end
    end
  end

  def interval_fill_zeros({data, meta}, from, to, rollup) do
    times = rollup.range(from, to)
    {fill_zeros(data, times), meta}
  end

  defp fill_zeros([result | rest_results] = data, [dtim | rest_dtims]) do
    if Timex.equal?(dtim, result.time) do
      [result] ++ fill_zeros(rest_results, rest_dtims)
    else
      [%{count: 0, time: dtim}] ++ fill_zeros(data, rest_dtims)
    end
  end
  defp fill_zeros([], [dtim | rest]), do: [%{count: 0, time: dtim}] ++ fill_zeros([], rest)
  defp fill_zeros([], []), do: []

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
