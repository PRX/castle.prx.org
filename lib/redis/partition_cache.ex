defmodule Castle.Redis.PartitionCache do
  alias Castle.Redis.Conn, as: Conn

  def partition(key, combiner_fn, worker_fns) do
    get_parts(key, 0, nil, worker_fns) |> combine(combiner_fn)
  end
  def partition(key, fns), do: partition(key, fn(parts) -> parts end, fns)

  def partition_get(key, num_parts, combiner_fn) do
    parts = Enum.map 0..(num_parts - 1), fn(index) ->
      case Conn.get("#{key}.#{index}") do
        nil -> {[], %{cached: true}}
        [_, _, val] -> {val, %{cached: true}}
      end
    end
    combine(parts, combiner_fn)
  end
  def partition_get(key, num), do: partition_get(key, num, fn(parts) -> parts end)

  defp get_parts(key, index, date, [_part | rest] = parts) do
    case Conn.get("#{key}.#{index}") do
      nil ->
        get_parts_uncached(key, index, date, parts)
      [expires, next_date, val] ->
        if expired?(expires) do
          get_parts_uncached(key, index, date, parts)
        else
          [{val, %{cached: true}}] ++ get_parts(key, index + 1, parse(next_date), rest)
        end
    end
  end
  defp get_parts(_key, _index, _date, []), do: []

  defp get_parts_uncached(key, index, date, [work_fn | rest]) when is_function(work_fn) do
    get_parts_uncached(key, index, date, [{nil, work_fn}] ++ rest)
  end
  defp get_parts_uncached(key, index, date, [{ttl, work_fn} | rest]) do
    {next_date, val, meta} = case call_fn(work_fn, date) do
      {v, m} -> {nil, v, m}
      {k, v, m} -> {k, v, m}
    end
    Conn.set("#{key}.#{index}", [expiration(ttl), format(next_date), val])
    [{val, meta}] ++ get_parts_uncached(key, index + 1, next_date, rest)
  end
  defp get_parts_uncached(_key, _index, _date, []), do: []

  defp call_fn(work_fn, nil), do: work_fn.()
  defp call_fn(work_fn, date), do: work_fn.(date)

  defp format(nil), do: nil
  defp format(dtim) do
    {:ok, formatted} = Timex.format(dtim, "{ISO:Extended:Z}")
    formatted
  end

  defp parse(nil), do: nil
  defp parse(dtim_str) do
    {:ok, dtim} = Timex.parse(dtim_str, "{ISO:Extended:Z}")
    dtim
  end

  defp expiration(nil), do: nil
  defp expiration(ttl), do: Timex.now |> Timex.shift(seconds: ttl) |> format()

  defp expired?(nil), do: false
  defp expired?(expiration_str), do: Timex.compare(Timex.now(), parse(expiration_str)) > 0

  defp combine(parts, combiner_fn) do
    data = parts
      |> Enum.map(fn({result, _meta}) -> result end)
      |> Enum.concat()
      |> combiner_fn.()
    meta = parts
      |> Enum.map(fn({_result, meta}) -> meta end)
      |> combine_meta()
    {data, meta}
  end

  defp combine_meta(metas) do
    metas
    |> Enum.map(&Map.to_list/1)
    |> Enum.concat()
    |> Enum.reduce(%{}, fn({key, val}, acc) ->
      Map.merge acc, Map.put(%{}, key, val), fn k, v1, v2 ->
        case k do
          :cached -> v1 && v2
          _ when is_number(v1) and is_number(v2) -> v1 + v2
          _ when is_list(v1) and is_list(v2) -> v1 ++ v2
          _ when is_list(v1) and not is_list(v2) -> v1 ++ [v2]
          _ when is_list(v2) and not is_list(v1) -> [v1] ++ v2
          _ -> [v1, v2]
        end
      end
    end)
  end
end
