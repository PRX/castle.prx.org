defmodule CastleWeb.API.TotalView do
  use CastleWeb, :view

  def render("total.json", %{id: id, interval: intv, group: group, downloads: data}) do
    %{
      id: id,
      group: group_json(group),
      interval: interval_json(intv),
      downloads: Enum.map(data, &total_json/1),
    }
  end

  defp group_json(%{name: name}) do
    %{name: name}
  end

  defp interval_json(%{from: from, to: to, bucket: _bucket}) do
    %{from: format_dtim(from), to: format_dtim(to)}
  end
  defp interval_json(any), do: any

  defp total_json(%{group: group, count: count}), do: [group, count]

  defp format_dtim(dtim) do
    {:ok, formatted} = Timex.format(dtim, "{ISO:Extended:Z}")
    formatted
  end
end
