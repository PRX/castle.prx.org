defmodule CastleWeb.API.EpisodeController do
  use CastleWeb, :controller
  alias Castle.Rollup.Query.Totals, as: Totals

  @redis Application.get_env(:castle, :redis)

  def index(%{assigns: %{podcast: podcast}} = conn, params) do
    {page, per} = parse_paging(params)
    {search} = CastleWeb.Search.parse_search(params)

    queryable =
      Castle.Episode.recent_query(podcast.id)
      |> Castle.Episode.undeleted()
      |> CastleWeb.Search.filter_title_search(search)

    total = Castle.Episode.total(queryable)
    episodes = CastleWeb.Paging.paginated_results(queryable, per, page)
    paging = %{page: page, per: per, total: total, podcast_id: podcast.id, search: search}
    render(conn, "index.json", conn: conn, episodes: episodes, paging: paging)
  end

  def index(%{prx_user: user} = conn, params) do
    {page, per} = parse_paging(params)
    {search} = CastleWeb.Search.parse_search(params)
    accounts = PrxAuth.authorized_resources(user, :castle, :read_private)

    queryable =
      Castle.Episode.recent_query(accounts)
      |> Castle.Episode.undeleted()
      |> CastleWeb.Search.filter_title_search(search)

    total = Castle.Episode.total(queryable)
    episodes = CastleWeb.Paging.paginated_results(queryable, per, page)
    paging = %{page: page, per: per, total: total, search: search}
    render(conn, "index.json", conn: conn, episodes: episodes, paging: paging)
  end

  def show(%{assigns: %{episode: episode}} = conn, _params) do
    total =
      @redis.episode_totals_cache(episode.id, fn to_dtim ->
        Totals.episode_totals(episode.id, to_dtim)
      end)

    render(conn, "show.json", conn: conn, episode: episode, trends: %{total: total})
  end
end
