defmodule Porter.API.DownloadController do
  use Porter.Web, :controller

  alias Porter.Redis.CachedResponse, as: Redis

  plug Porter.Plugs.ParseInt, "podcast_id"

  @downloads_ttl 15

  def index(conn, %{"podcast_id" => podcast_id}) do
    %{assigns: %{time_from: from, time_to: to, interval: interval}} = conn

    fetch = fn() -> BigQuery.podcast_downloads(podcast_id, from, to, interval) end
    {data, meta} = Redis.cached key("podcast", podcast_id, from, to, interval), @downloads_ttl, fetch

    render conn, "podcast.json",
      id: podcast_id,
      interval: interval,
      downloads: data,
      meta: meta
  end

  def index(conn, %{"episode_guid" => episode_guid}) do
    %{assigns: %{time_from: from, time_to: to, interval: interval}} = conn

    fetch = fn() -> BigQuery.episode_downloads(episode_guid, from, to, interval) end
    {data, meta} = Redis.cached key("episode", episode_guid, from, to, interval), @downloads_ttl, fetch

    render conn, "episode.json",
      guid: episode_guid,
      interval: interval,
      downloads: data,
      meta: meta
  end

  defp key(type, id, from, to, interval) do
    if Timex.compare(to, Timex.now) > 0 do
      "#{type}.downloads.#{id}.#{from}.now.#{interval}"
    else
      "#{type}.downloads.#{id}.#{from}.#{to}.#{interval}"
    end
  end
end
