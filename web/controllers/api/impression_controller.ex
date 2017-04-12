defmodule Castle.API.ImpressionController do
  use Castle.Web, :controller

  alias Castle.Redis.CachedResponse, as: Redis

  plug Castle.Plugs.ParseInt, "podcast_id"

  @impressions_ttl 15

  def index(conn, %{"podcast_id" => podcast_id}) do
    %{assigns: %{time_from: from, time_to: to, interval: interval}} = conn

    fetch = fn() -> BigQuery.podcast_impressions(podcast_id, from, to, interval) end
    {data, meta} = Redis.cached key("podcast", podcast_id, from, to, interval), @impressions_ttl, fetch

    render conn, "podcast.json",
      id: podcast_id,
      interval: interval,
      impressions: data,
      meta: meta
  end

  def index(conn, %{"episode_guid" => episode_guid}) do
    %{assigns: %{time_from: from, time_to: to, interval: interval}} = conn

    fetch = fn() -> BigQuery.episode_impressions(episode_guid, from, to, interval) end
    {data, meta} = Redis.cached key("episode", episode_guid, from, to, interval), @impressions_ttl, fetch

    render conn, "episode.json",
      guid: episode_guid,
      interval: interval,
      impressions: data,
      meta: meta
  end

  defp key(type, id, from, to, interval) do
    if Timex.compare(to, Timex.now) > 0 do
      "#{type}.impressions.#{id}.#{from}.now.#{interval}"
    else
      "#{type}.impressions.#{id}.#{from}.#{to}.#{interval}"
    end
  end
end
