defmodule CastleWeb.API.PodcastController do
  use CastleWeb, :controller
  alias Castle.Rollup.Query.Totals, as: Totals

  @redis Application.get_env(:castle, :redis)

  def index(%{prx_user: user} = conn, params) do
    {page, per} = parse_paging(params)
    {search} = CastleWeb.Search.parse_search(params)
    accounts = Map.keys(user.auths)

    queryable =
      Castle.Podcast.recent_query(accounts)
      |> CastleWeb.Search.filter_title_search(search)

    total = Castle.Podcast.total(queryable)
    podcasts = paginated_results(queryable, per, page)
    paging = %{page: page, per: per, total: total, search: search}
    render(conn, "index.json", conn: conn, podcasts: podcasts, paging: paging)
  end

  def show(%{assigns: %{podcast: podcast}} = conn, _params) do
    total =
      @redis.podcast_totals_cache(podcast.id, fn to_dtim ->
        Totals.podcast_totals(podcast.id, to_dtim)
      end)

    render(conn, "show.json", conn: conn, podcast: podcast, trends: %{total: total})
  end
end
