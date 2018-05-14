defmodule Castle.Redis.Increments do

  alias Castle.Redis.Conn, as: Conn

  def get_podcast(id, intv, now \\ Timex.now) do
    get_increments("downloads.podcasts", id, intv, now)
  end

  def get_episode(guid, intv, now \\ Timex.now) do
    get_increments("downloads.episodes", guid, intv, now)
  end

  def get_increments(prefix, id, intv, now) do
    cache_from = dtim_max(cache_boundary(now), intv.from)
    round_to_now = dtim_min(intv.to, now)
    range = Castle.Bucket.Hourly.range(cache_from, round_to_now)
    keys = cache_keys(prefix, range)

    # if any cache hits, return the new interval
    case cache_hget(keys, id, range) do
      nil ->
        {nil, nil} # cache miss
      data ->
        case Timex.compare(intv.from, cache_from) do
          -1 -> {data, Map.put(intv, :to, cache_from)} # hit - update interval
          _ -> {data, nil} # no more data
        end
    end
  end

  # consider postgres hourly_downloads "complete" 15 minutes after the hour
  def cache_boundary(now) do
    now |> Timex.shift(minutes: -15) |> Castle.Bucket.Hourly.floor()
  end

  defp cache_keys(_prefix, []), do: []
  defp cache_keys(prefix, [dtim | rest]) do
    {:ok, dtim_str} = Timex.format(dtim, "{ISO:Extended:Z}")
    ["#{prefix}.HOUR.#{dtim_str}"] ++ cache_keys(prefix, rest)
  end

  defp cache_hget([], _id, _range), do: nil
  defp cache_hget(keys, id, range) do
    vals = Conn.hget(keys, id) |> Enum.map(fn([_exists, val]) -> val end)
    case Enum.all?(vals, &(&1 != nil)) do
      false -> nil
      true -> format_values(vals, range)
    end
  end

  defp format_values([], []), do: []
  defp format_values([count | rest_counts], [time | rest_times]) do
    [%{count: count, time: time}] ++ format_values(rest_counts, rest_times)
  end

  defp dtim_min(a, b), do: if Timex.compare(a, b) == 1, do: b, else: a
  defp dtim_max(a, b), do: if Timex.compare(a, b) == 1, do: a, else: b
end
