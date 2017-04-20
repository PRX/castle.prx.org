defmodule Castle.API.PodcastController do
  use Castle.Web, :controller

  @redis Application.get_env(:castle, :redis)
  @bigquery Application.get_env(:castle, :bigquery)

  plug Castle.Plugs.ParseInt, "id" when action == :show

  @index_ttl 900
  @show_ttl 300

  def index(conn, _params) do
    {podcasts, meta} = @redis.cached "podcast.index", @index_ttl, fn() -> @bigquery.podcasts() end
    render conn, "index.json", conn: conn, podcasts: podcasts, meta: meta
  end

  def show(conn, %{"id" => id}) do
    {podcast, meta} = @redis.cached "podcast.show.#{id}", @show_ttl, fn() -> @bigquery.podcast(id) end
    render conn, "show.json", conn: conn, podcast: podcast, meta: meta
  end
end
