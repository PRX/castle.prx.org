defmodule CastleWeb.API.ImpressionController do
  use CastleWeb, :controller

  alias CastleWeb.API.IntervalView, as: IntervalView

  @redis Application.get_env(:castle, :redis)
  @bigquery Application.get_env(:castle, :bigquery)
  @group_ttl 900

  plug Castle.Plugs.ParseInt, "podcast_id"

  def index(%{assigns: %{interval: intv, group: group}} = conn, %{"podcast_id" => id}) do
    {data, meta} = @redis.cached key("podcast.#{id}", intv, group), @group_ttl, fn() ->
      @bigquery.podcast_impressions(id, intv, group)
    end
    render conn, IntervalView, "podcast-group.json", id: id, interval: intv.rollup.name,
      group: group.name, impressions: data, meta: meta
  end

  def index(%{assigns: %{interval: intv}} = conn, %{"podcast_id" => id}) do
    {data, meta} = @redis.interval "impressions.podcasts", intv, id, fn(new_intv) ->
      @bigquery.podcast_impressions(new_intv)
    end
    render conn, IntervalView, "podcast.json", id: id, interval: intv.rollup.name,
      impressions: data, meta: meta
  end

  def index(%{assigns: %{interval: intv, group: group}} = conn, %{"episode_guid" => guid}) do
    {data, meta} = @redis.cached key("episode.#{guid}", intv, group), @group_ttl, fn() ->
      @bigquery.episode_impressions(guid, intv, group)
    end
    render conn, IntervalView, "episode-group.json", guid: guid, interval: intv.rollup.name,
      group: group.name, impressions: data, meta: meta
  end

  def index(%{assigns: %{interval: intv}} = conn, %{"episode_guid" => guid}) do
    {data, meta} = @redis.interval "impressions.episodes", intv, guid, fn(new_intv) ->
      @bigquery.episode_impressions(new_intv)
    end
    render conn, IntervalView, "episode.json", guid: guid, interval: intv.rollup.name,
      impressions: data, meta: meta
  end

  defp key(id, intv, group) do
    "impressions.#{id}.#{key_interval(intv)}.group.#{group.name}.#{group.limit}"
  end

  defp key_interval(intv) do
    {:ok, from} = Timex.format(intv.from, "{ISO:Extended:Z}")
    {:ok, to} = Timex.format(intv.to, "{ISO:Extended:Z}")
    "#{intv.rollup.name}.#{from}.#{to}"
  end
end
