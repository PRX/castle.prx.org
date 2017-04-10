defmodule Porter.API.DownloadController do
  use Porter.Web, :controller

  def index(conn, %{"podcast_id" => podcast_id}) do
    %{assigns: %{time_from: from, time_to: to, interval: interval}} = conn
    {data, meta} = BigQuery.podcast_downloads(podcast_id, from, to, interval)
    render conn, "podcast.json",
      id: String.to_integer(podcast_id),
      interval: interval,
      downloads: data,
      meta: meta
  end

  def index(conn, %{"episode_guid" => episode_guid}) do
    %{assigns: %{time_from: from, time_to: to, interval: interval}} = conn

    {data, meta} = BigQuery.episode_downloads(episode_guid, from, to, interval)
    render conn, "episode.json",
      guid: episode_guid,
      interval: interval,
      downloads: data,
      meta: meta
  end
end
