defmodule Castle.API.ImpressionView do
  use Castle.Web, :view

  def render("podcast.json", %{id: id} = data) do
    impression_json(%{id: id}, data)
  end

  def render("episode.json", %{guid: guid} = data) do
    impression_json(%{guid: guid}, data)
  end

  defp impression_json(data, %{interval: interval, impressions: impressions, meta: meta}) do
    %{
      interval: interval,
      impressions: Enum.map(impressions, &count_json/1),
      meta: meta,
    }
    |> Map.merge(data)
  end

  defp count_json(impression) do
    [impression.time, impression.count]
  end
end
