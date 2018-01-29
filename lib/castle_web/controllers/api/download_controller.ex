defmodule CastleWeb.API.DownloadController do
  use CastleWeb, :controller

  alias CastleWeb.API.IntervalView, as: IntervalView

  @redis Application.get_env(:castle, :redis)
  @bigquery Application.get_env(:castle, :bigquery)
  @group_ttl 900

  plug Castle.Plugs.ParseInt, "podcast_id"

  def index(%{assigns: %{interval: intv, group: group}} = conn, %{"podcast_id" => id}) do
    {data, meta} = group_cache_podcast(intv, group, id)
    render conn, IntervalView, "podcast-group.json", id: id, interval: intv.bucket.name,
      group: group.name, downloads: data, meta: meta
  end

  def index(%{assigns: %{interval: intv}} = conn, %{"podcast_id" => id}) do
    {data, meta} = cache_podcast(intv, id) |> bucketize(intv)
    render conn, IntervalView, "podcast.json", id: id, interval: intv.bucket.name,
      downloads: data, meta: meta
  end

  def index(%{assigns: %{interval: intv, group: group}} = conn, %{"episode_guid" => guid}) do
    {data, meta} = group_cache_episode(intv, group, guid)
    render conn, IntervalView, "episode-group.json", guid: guid, interval: intv.bucket.name,
      group: group.name, downloads: data, meta: meta
  end

  def index(%{assigns: %{interval: intv}} = conn, %{"episode_guid" => guid}) do
    {data, meta} = cache_episode(intv, guid) |> bucketize(intv)
    render conn, IntervalView, "episode.json", guid: guid, interval: intv.bucket.name,
      downloads: data, meta: meta
  end

  defp cache_podcast(intv, id) do
    @redis.interval "downloads.podcasts", intv, id, fn(new_intv) ->
      @bigquery.podcast_downloads(new_intv)
    end
  end

  defp cache_episode(intv, guid) do
    @redis.interval "downloads.episodes", intv, guid, fn(new_intv) ->
      @bigquery.episode_downloads(new_intv)
    end
  end

  defp group_cache_podcast(intv, group, id) do
    intv_nobucket = intv |> Map.put(:rollup, intv.bucket) |> Map.put(:bucket, nil)
    @redis.cached key("podcast.#{id}", intv_nobucket, group), @group_ttl, fn() ->
      @bigquery.podcast_downloads(id, intv_nobucket, group)
    end
  end

  defp group_cache_episode(intv, group, guid) do
    intv_nobucket = intv |> Map.put(:rollup, intv.bucket) |> Map.put(:bucket, nil)
    @redis.cached key("episode.#{guid}", intv_nobucket, group), @group_ttl, fn() ->
      @bigquery.episode_downloads(guid, intv_nobucket, group)
    end
  end

  defp key(id, intv, group) do
    "downloads.#{id}.#{key_interval(intv)}.group.#{group.name}.#{group.limit}"
  end

  defp key_interval(intv) do
    {:ok, from} = Timex.format(intv.from, "{ISO:Extended:Z}")
    {:ok, to} = Timex.format(intv.to, "{ISO:Extended:Z}")
    "#{intv.rollup.name}.#{from}.#{to}"
  end
end
