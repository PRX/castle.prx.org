defmodule Castle.API.Helpers do

  def meta_json(json, %{interval: interval, meta: meta}) do
    json |> Map.merge(%{interval: interval, meta: meta})
  end
  def meta_json(json, %{meta: meta}) do
    json |> Map.put(:meta, meta)
  end

  def counts_json(json, %{downloads: downloads}) do
    json |> Map.put(:downloads, Enum.map(downloads, &count_json/1))
  end
  def counts_json(json, %{impressions: impressions}) do
    json |> Map.put(:impressions, Enum.map(impressions, &count_json/1))
  end

  defp count_json(data), do: [data.time, data.count]

  def groups_json(json, %{downloads: downloads}) do
    json |> group_names(downloads) |> Map.put(:downloads, grouped(downloads))
  end
  def groups_json(json, %{impressions: impressions}) do
    json |> group_names(impressions) |> Map.put(:impressions, grouped(impressions))
  end

  defp group_names(json, data) do
    names = group_ranks(data) |> Enum.map(&group_find_rank(data, &1))
    json |> Map.put(:groups, names)
  end

  defp group_ranks(data) do
    data |> Enum.map(&(&1.rank)) |> Enum.uniq() |> Enum.sort()
  end

  defp group_find_rank(data, rank) do
    Enum.find_value data, "Other", &(if &1.rank == rank do &1.display end)
  end

  defp grouped(raw_data) do
    ranks = group_ranks(raw_data)
    raw_data
    |> Enum.group_by(&("#{&1.time}"), &(&1))
    |> Enum.sort()
    |> Enum.map(fn({_time, data}) -> [hd(data).time | group_fill_blanks(data, ranks)] end)
  end

  defp group_fill_blanks(data, ranks) do
    Enum.map ranks, fn(rank) ->
      Enum.find_value data, 0, &(if &1.rank == rank do &1.count end)
    end
  end
end
