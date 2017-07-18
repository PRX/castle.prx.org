defmodule Castle.API.DownloadController do
  use Castle.Web, :controller

  @redis Application.get_env(:castle, :redis)
  @bigquery Application.get_env(:castle, :bigquery)
  @group_ttl 900

  plug Castle.Plugs.ParseInt, "podcast_id"

  def index(%{assigns: %{interval: intv, group: group}} = conn, %{"podcast_id" => id}) do
    {data, meta} = @redis.cached key("podcast.#{id}", group), @group_ttl, fn() ->
      @bigquery.podcast_downloads(id, intv, group)
    end
    render conn, "podcast-group.json", id: id, interval: intv.seconds,
      group: group.name, downloads: data, meta: meta
  end

  def index(%{assigns: %{interval: intv}} = conn, %{"podcast_id" => id}) do
    {data, meta} = @redis.interval key("podcast.#{id}"), intv, fn(new_intv) ->
      @bigquery.podcast_downloads(id, new_intv)
    end
    render conn, "podcast.json", id: id, interval: intv.seconds,
      downloads: data, meta: meta
  end

  def index(%{assigns: %{interval: intv, group: group}} = conn, %{"episode_guid" => guid}) do
    {data, meta} = @redis.cached key("episode.#{guid}", group), @group_ttl, fn() ->
      @bigquery.episode_downloads(guid, intv, group)
    end
    render conn, "episode-group.json", guid: guid, interval: intv.seconds,
      group: group.name, downloads: data, meta: meta
  end

  def index(%{assigns: %{interval: intv}} = conn, %{"episode_guid" => guid}) do
    {data, meta} = @redis.interval key("episode.#{guid}"), intv, fn(new_intv) ->
      @bigquery.episode_downloads(guid, new_intv)
    end
    render conn, "episode.json", guid: guid, interval: intv.seconds,
      downloads: data, meta: meta
  end

  defp key(id), do: "downloads.#{id}"
  defp key(id, group), do: "downloads.#{id}.group.#{group.name}.#{group.limit}"
end
