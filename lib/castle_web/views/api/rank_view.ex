defmodule CastleWeb.API.RankView do
  use CastleWeb, :view

  def render("rank.json", %{id: id, interval: intv, group: group, ranks: ranks, downloads: data}) do
    totals = sum_downloads(data)
    %{
      id: id,
      group: group_json(group),
      interval: interval_json(intv),
      ranks: ranks_json(ranks, totals, group),
      downloads: downloads_json(data),
    }
  end

  defp sum_downloads(data) do
    data
    |> Enum.map(&(&1.counts))
    |> Enum.zip
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(&Enum.sum/1)
  end

  defp group_json(%{name: name, limit: limit}) do
    %{name: name, limit: limit}
  end

  defp interval_json(%{from: from, to: to, bucket: bucket}) do
    %{name: bucket.name(), from: format_dtim(from), to: format_dtim(to)}
  end
  defp interval_json(any), do: any

  defp ranks_json([], [], _group), do: []
  defp ranks_json([code | rest], [total | rest_totals], %{labels: labels} = group) do
    [%{
      code: code,
      label: labels.find(code),
      total: total,
    }] ++ ranks_json(rest, rest_totals, group)
  end

  defp downloads_json([]), do: []
  defp downloads_json([%{time: time, counts: counts} | rest]) do
    [[format_dtim(time), counts]] ++ downloads_json(rest)
  end

  defp format_dtim(dtim) do
    {:ok, formatted} = Timex.format(dtim, "{ISO:Extended:Z}")
    formatted
  end
end
