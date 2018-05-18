defmodule CastleWeb.API.PodcastController do
  use CastleWeb, :controller
  alias Castle.Rollup.Query.Trends, as: Trends

  @redis Application.get_env(:castle, :redis)

  plug Castle.Plugs.ParseInt, "id" when action == :show

  def index(conn, params) do
    {page, per} = parse_paging(params)
    podcasts = Castle.Podcast.recent(per, page)
    paging = %{page: page, per: per, total: Castle.Podcast.total()}
    render conn, "index.json", conn: conn, podcasts: podcasts, paging: paging
  end

  def show(conn, %{"id" => id}) do
    case Castle.Repo.get(Castle.Podcast, id) do
      nil ->
        send_resp conn, 404, "Podcast #{id} not found"
      podcast ->
        trends = @redis.podcast_trends_cache id, fn(to_dtim) ->
          Trends.podcast_trends(id, to_dtim)
        end
        render conn, "show.json", conn: conn, podcast: podcast, trends: trends
    end
  end
end
