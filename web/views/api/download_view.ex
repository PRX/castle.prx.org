defmodule Porter.API.DownloadView do
  use Porter.Web, :view

  def render("podcast.json", %{id: id} = data) do
    download_json(%{id: id}, data)
  end

  def render("episode.json", %{guid: guid} = data) do
    download_json(%{guid: guid}, data)
  end

  defp download_json(data, %{interval: interval, downloads: downloads, meta: meta}) do
    %{
      interval: interval,
      downloads: Enum.map(downloads, &count_json/1),
      meta: meta,
    }
    |> Map.merge(data)
  end

  defp count_json(download) do
    [download.time, download.count]
  end
end
