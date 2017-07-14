defmodule Castle.API.ImpressionController do
  use Castle.Web, :controller

  @redis Application.get_env(:castle, :redis)
  @bigquery Application.get_env(:castle, :bigquery)

  plug Castle.Plugs.ParseInt, "podcast_id"

  def index(conn, %{"podcast_id" => podcast_id}) do
    %{assigns: %{interval: intv}} = conn

    {data, meta} = @redis.interval "impressions.podcast.#{podcast_id}", intv, fn(new_intv) ->
      @bigquery.podcast_impressions(podcast_id, new_intv)
    end

    render conn, "podcast.json",
      id: podcast_id,
      interval: intv.seconds,
      impressions: data,
      meta: meta
  end

  def index(conn, %{"episode_guid" => episode_guid}) do
    %{assigns: %{interval: intv}} = conn

    {data, meta} = @redis.interval "impressions.episode.#{episode_guid}", intv, fn(new_intv) ->
      @bigquery.episode_impressions(episode_guid, new_intv)
    end

    render conn, "episode.json",
      guid: episode_guid,
      interval: intv.seconds,
      impressions: data,
      meta: meta
  end
end
