defmodule CastleWeb.API.RankView do
  use CastleWeb, :view

  def render("rank.json", %{id: id, interval: intv, group: group, ranks: ranks, downloads: data}) do
    %{
      id: id,
      group: group_json(group),
      interval: interval_json(intv),
      ranks: ranks,
      downloads: Enum.map(data, &download_json/1),
    }
  end

  defp group_json(%{name: name, limit: limit}) do
    %{name: name, limit: limit}
  end

  defp interval_json(%{from: from, to: to, bucket: bucket}) do
    %{name: bucket.name(), from: format_dtim(from), to: format_dtim(to)}
  end
  defp interval_json(any), do: any

  defp download_json(%{time: time, counts: counts, ranks: _ranks}) do
    [format_dtim(time), counts]
  end

  defp format_dtim(dtim) do
    {:ok, formatted} = Timex.format(dtim, "{ISO:Extended:Z}")
    formatted
  end
end
