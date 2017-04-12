defmodule Porter.API.PodcastController do
  use Porter.Web, :controller

  alias Porter.Redis.CachedResponse, as: Redis

  @index_ttl 900
  @show_ttl 300

  def index(conn, _params) do
    {podcasts, meta} = Redis.cached "podcast.index", @index_ttl, fn() -> BigQuery.podcasts() end
    render conn, "index.json", conn: conn, podcasts: podcasts, meta: meta
  end

  def show(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {num, _rem} ->
        {podcast, meta} = Redis.cached "podcast.show.#{num}", @show_ttl, fn() -> BigQuery.podcast(num) end
        render conn, "show.json", conn: conn, podcast: podcast, meta: meta
      :error ->
        conn |> put_status(404) |> text("Podcast #{id} not found")
    end
  end
end
