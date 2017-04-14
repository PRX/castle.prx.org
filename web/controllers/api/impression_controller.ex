defmodule Castle.API.ImpressionController do
  use Castle.Web, :controller

  alias Castle.Redis.IntervalResponse, as: Redis

  plug Castle.Plugs.ParseInt, "podcast_id"

  def index(conn, %{"podcast_id" => podcast_id}) do
    %{assigns: %{time_from: from, time_to: to, interval: interval}} = conn

    {data, meta} = Redis.interval "impressions.podcast.#{podcast_id}", from, to, interval, fn(new_from) ->
      BigQuery.podcast_impressions(podcast_id, new_from, to, interval)
    end

    render conn, "podcast.json",
      id: podcast_id,
      interval: interval,
      impressions: data,
      meta: meta
  end

  def index(conn, %{"episode_guid" => episode_guid}) do
    %{assigns: %{time_from: from, time_to: to, interval: interval}} = conn

    {data, meta} = Redis.interval "impressions.episode.#{episode_guid}", from, to, interval, fn(new_from) ->
      BigQuery.episode_impressions(episode_guid, new_from, to, interval)
    end

    render conn, "episode.json",
      guid: episode_guid,
      interval: interval,
      impressions: data,
      meta: meta
  end
end
