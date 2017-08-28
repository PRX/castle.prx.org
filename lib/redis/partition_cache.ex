defmodule Castle.Redis.PartitionCache do
  alias Castle.Redis.Conn, as: Conn

  def partition(key, combiner_fn, worker_fns) do
    parts = get_parts(key, 0, nil, worker_fns)
    data = parts
      |> Enum.map(fn({result, _meta}) -> result end)
      |> Enum.concat()
      |> combiner_fn.()
    meta = parts
      |> Enum.map(fn({_result, meta}) -> meta end)
      |> combine_meta()
    {data, meta}
  end
  def partition(key, fns), do: partition(key, fn(parts) -> parts end, fns)

  defp get_parts(key, index, date, [_part | rest] = parts) do
    case Conn.get("#{key}.#{index}") do
      nil ->
        get_parts_uncached(key, index, date, parts)
      [next_date, val] ->
        [{val, %{cached: true}}] ++ get_parts(key, index + 1, parse(next_date), rest)
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
    Conn.set("#{key}.#{index}", ttl, [format(next_date), val])
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

  defp combine_meta(metas) do
    metas
    |> Enum.map(&Map.to_list/1)
    |> Enum.concat()
    |> Enum.reduce(%{}, fn({key, val}, acc) ->
      Map.merge acc, Map.put(%{}, key, val), fn k, v1, v2 ->
        case k do
          :cached -> v1 && v2
          _ -> v1 + v2
        end
      end
    end)
  end
end
