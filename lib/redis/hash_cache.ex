defmodule Castle.Redis.HashCache do
  alias Castle.Redis.Conn, as: Conn

  @last_updated "_last_updated"

  def hash_cache(key, work_fn) do
    case lookup(key) do
      {:skip} ->
        {%{}, %{cached: true}}
      {:ok, from_dtim, to_dtim, old_data} ->
        {data, meta} = work_fn.(from_dtim, to_dtim)
        merged_data = stringify_keys(data)
          |> merge(old_data)
          |> Map.put(@last_updated, format(to_dtim))
        Conn.hsetall(key, merged_data)
        {data, Map.put(meta, :job, {from_dtim, to_dtim})}
    end
  end

  def hash_fetch(key, field), do: Conn.hget(key, field)
  def hash_fetch(key, field, supplement_fn) do
    last_updated = parse Conn.hget(key, @last_updated)
    case hash_fetch(key, field) do
      nil -> nil
      num -> num + supplement_fn.(last_updated)
    end
  end

  defp lookup(key) do
    today = Timex.beginning_of_day(Timex.now)
    if should_run? Conn.hget(key, @last_updated) do
      data = Conn.hgetall(key)
      dtim = Map.get(data, @last_updated)
      if should_run?(dtim) do
        {:ok, parse(dtim), today, Map.delete(data, @last_updated)}
      else
        {:skip}
      end
    else
      {:skip}
    end
  end

  defp should_run?(dtim_str) do
    case parse(dtim_str) do
      nil -> true
      dtim -> dtim != Timex.beginning_of_day(Timex.now)
    end
  end

  defp parse(nil), do: nil
  defp parse(dtim_str) do
    {:ok, dtim} = Timex.parse(dtim_str, "{ISO:Extended:Z}")
    dtim
  end

  defp format(nil), do: nil
  defp format(dtim) do
    {:ok, formatted} = Timex.format(dtim, "{ISO:Extended:Z}")
    formatted
  end

  def stringify_keys(data) do
    data
    |> Enum.map(fn({k, v}) -> {stringify_key(k), v} end)
    |> Enum.into(%{})
  end
  def stringify_key(k) when is_atom(k), do: Atom.to_string(k)
  def stringify_key(k), do: k

  defp merge(left, right) do
    (Map.keys(left) ++ Map.keys(right))
    |> Stream.uniq()
    |> Stream.map(&{&1, Map.get(left, &1, 0) + Map.get(right, &1, 0)})
    |> Enum.into(%{})
  end
end
