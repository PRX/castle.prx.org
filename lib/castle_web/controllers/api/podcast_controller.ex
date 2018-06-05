defmodule CastleWeb.API.PodcastController do
  use CastleWeb, :controller
  alias Castle.Rollup.Query.Trends, as: Trends

  @redis Application.get_env(:castle, :redis)

  def index(%{prx_user: user} = conn, params) do
    {page, per} = parse_paging(params)
    accounts = Map.keys(user.auths)
    podcasts = Castle.Podcast.recent(accounts, per, page)
    total = Castle.Podcast.total(accounts)
    paging = %{page: page, per: per, total: total}
    render conn, "index.json", conn: conn, podcasts: podcasts, paging: paging
  end

  def show(%{assigns: %{podcast: podcast}} = conn, _params) do
    trends = @redis.podcast_trends_cache podcast.id, fn(to_dtim) ->
      Trends.podcast_trends(podcast.id, to_dtim)
    end
    render conn, "show.json", conn: conn, podcast: podcast, trends: trends
  end
end
