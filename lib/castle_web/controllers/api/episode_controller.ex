defmodule CastleWeb.API.EpisodeController do
  use CastleWeb, :controller
  alias Castle.Rollup.Query.Trends, as: Trends

  @redis Application.get_env(:castle, :redis)

  plug Castle.Plugs.AuthPodcast, "podcast_id"
  plug Castle.Plugs.AuthEpisode, "id"

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
    trends = @redis.episode_trends_cache episode.id, fn(to_dtim) ->
      Trends.episode_trends(episode.id, to_dtim)
    end
    render conn, "show.json", conn: conn, episode: episode, trends: trends
  end
end
