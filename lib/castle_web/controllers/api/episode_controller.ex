defmodule CastleWeb.API.EpisodeController do
  use CastleWeb, :controller
  alias Castle.Rollup.Query.Totals, as: Totals

  @redis Application.get_env(:castle, :redis)

  def index(%{assigns: %{podcast: podcast}} = conn, params) do
    {page, per} = parse_paging(params)
    episodes = Castle.Episode.recent(podcast.id, per, page)
    total = Castle.Episode.total(podcast.id)
    paging = %{page: page, per: per, total: total, podcast_id: podcast.id}
    render conn, "index.json", conn: conn, episodes: episodes, paging: paging
  end
  def index(%{prx_user: user} = conn, params) do
    {page, per} = parse_paging(params)
    accounts = Map.keys(user.auths)
    episodes = Castle.Episode.recent(accounts, per, page)
    total = Castle.Episode.total(accounts)
    paging = %{page: page, per: per, total: total}
    render conn, "index.json", conn: conn, episodes: episodes, paging: paging
  end

  def show(%{assigns: %{episode: episode}} = conn, _params) do
    total = @redis.episode_totals_cache episode.id, fn(to_dtim) ->
      Totals.episode_totals(episode.id, to_dtim)
    end
    render conn, "show.json", conn: conn, episode: episode, trends: %{total: total}
  end
end
