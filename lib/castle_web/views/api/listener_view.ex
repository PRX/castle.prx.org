defmodule CastleWeb.API.ListenerView do
  use CastleWeb, :view

  def render("download.json", %{id: id, interval: intv, downloads: data}) do
    %{
      id: id,
      interval: interval_json(intv),
      listeners: Enum.map(data, &count_json/1),
    }
  end

  defp interval_json(%{from: from, to: to, bucket: bucket}) do
    %{name: bucket.name(), from: format_dtim(from), to: format_dtim(to)}
  end
  defp interval_json(any), do: any

  defp count_json(data), do: [format_dtim(data.time), data.count]

  defp format_dtim(dtim) do
    {:ok, formatted} = Timex.format(dtim, "{ISO:Extended:Z}")
    formatted
  end
end
