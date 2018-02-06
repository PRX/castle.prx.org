defmodule Castle.Rollup.Data.Trends do
  import Castle.Rollup.Jobs.Trends

  def podcast(id) do
    {result, _meta} = get()
    result
    |> Enum.filter(&(&1.feeder_podcast == id))
    |> sum_fields()
  end

  def episode(guid) do
    {result, _meta} = get()
    result
    |> Enum.filter(&(&1.feeder_episode == guid))
    |> sum_fields()
  end

  defp sum_fields([]), do: sum_fields(%{}, [%{}])
  defp sum_fields(data), do: sum_fields(%{}, data)
  defp sum_fields(acc, [first | rest]) do
    acc
    |> sum_field(first, :last7)
    |> sum_field(first, :this7)
    |> sum_field(first, :yesterday)
    |> sum_field(first, :today)
    |> sum_fields(rest)
  end
  defp sum_fields(acc, []), do: acc

  defp sum_field(left, right, key) do
    sum = Map.get(left, key, 0) + Map.get(right, key, 0)
    Map.put(left, key, sum)
  end
end
