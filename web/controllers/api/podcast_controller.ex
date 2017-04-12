defmodule Porter.API.PodcastController do
  use Porter.Web, :controller

  alias Porter.Redis.CachedResponse, as: Redis

  plug Porter.Plugs.ParseInt, "id" when action == :show

  @index_ttl 900
  @show_ttl 300

  def index(conn, _params) do
    {podcasts, meta} = Redis.cached "podcast.index", @index_ttl, fn() -> BigQuery.podcasts() end
    render conn, "index.json", conn: conn, podcasts: podcasts, meta: meta
  end

  def show(conn, %{"id" => id}) do
    {podcast, meta} = Redis.cached "podcast.show.#{id}", @show_ttl, fn() -> BigQuery.podcast(id) end
    render conn, "show.json", conn: conn, podcast: podcast, meta: meta
  end
end
