defmodule CastleWeb.API.IntervalView do
  use CastleWeb, :view

  def render("podcast.json", %{id: id} = data) do
    %{id: id} |> meta_json(data) |> counts_json(data)
  end

  def render("podcast-group.json", %{id: id} = data) do
    %{id: id} |> meta_json(data) |> groups_json(data)
  end

  def render("episode.json", %{guid: guid} = data) do
    %{guid: guid} |> meta_json(data) |> counts_json(data)
  end

  def render("episode-group.json", %{guid: guid} = data) do
    %{guid: guid} |> meta_json(data) |> groups_json(data)
  end

  defp meta_json(json, %{interval: intv, meta: meta}) do
    json |> Map.merge(%{interval: interval_json(intv), meta: meta})
  end
  defp meta_json(json, %{meta: meta}) do
    json |> Map.put(:meta, meta)
  end

  defp interval_json(%{from: from, to: to, bucket: bucket}) do
    %{name: bucket.name(), from: format_dtim(from), to: format_dtim(to)}
  end
  defp interval_json(any), do: any

  defp counts_json(json, %{downloads: downloads}) do
    json |> Map.put(:downloads, Enum.map(downloads, &count_json/1))
  end
  defp counts_json(json, %{impressions: impressions}) do
    json |> Map.put(:impressions, Enum.map(impressions, &count_json/1))
  end

  defp count_json(data), do: [format_dtim(data.time), data.count]

  defp format_dtim(dtim) do
    {:ok, formatted} = Timex.format(dtim, "{ISO:Extended:Z}")
    formatted
  end

  defp groups_json(json, %{group: name, downloads: downloads}) do
    json
    |> group_names(downloads)
    |> Map.put(:group, name)
    |> Map.put(:downloads, grouped(downloads))
  end
  defp groups_json(json, %{group: name, impressions: impressions}) do
    json
    |> group_names(impressions)
    |> Map.put(:group, name)
    |> Map.put(:impressions, grouped(impressions))
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
