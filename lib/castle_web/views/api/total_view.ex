defmodule CastleWeb.API.TotalView do
  use CastleWeb, :view

  def render("total.json", %{id: id, interval: intv, group: group, downloads: data}) do
    %{
      id: id,
      group: group_json(group),
      interval: interval_json(intv),
      downloads: totals_json(data, group),
    }
  end

  defp group_json(%{name: name}) do
    %{name: name}
  end

  defp interval_json(%{from: from, to: to, bucket: _bucket}) do
    %{from: format_dtim(from), to: format_dtim(to)}
  end
  defp interval_json(any), do: any

  defp totals_json([], _group), do: []
  defp totals_json([%{group: code, count: n} | rest], %{labels: labels} = group) do
    [%{code: code, label: labels.find(code), count: n}] ++ totals_json(rest, group)
  end

  defp format_dtim(dtim) do
    {:ok, formatted} = Timex.format(dtim, "{ISO:Extended:Z}")
    formatted
  end
end
