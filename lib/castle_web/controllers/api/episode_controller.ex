defmodule CastleWeb.API.EpisodeController do
  use CastleWeb, :controller

  def index(conn, %{"podcast_id" => podcast_id} = params) do
    {page, per} = parse_paging(params)
    episodes = Castle.Episode.recent(podcast_id, per, page)
    paging = %{page: page, per: per, total: Castle.Episode.total(podcast_id), podcast_id: podcast_id}
    render conn, "index.json", conn: conn, episodes: episodes, paging: paging
  end
  def index(conn, params) do
    {page, per} = parse_paging(params)
    episodes = Castle.Episode.recent(per, page)
    paging = %{page: page, per: per, total: Castle.Episode.total()}
    render conn, "index.json", conn: conn, episodes: episodes, paging: paging
  end

  def show(conn, %{"id" => id}) do
    case Castle.Repo.get(Castle.Episode, id) do
      nil ->
        send_resp conn, 404, "Episode #{id} not found"
      episode ->
        trends = Castle.Rollup.Query.Trends.episode_trends(id)
        render conn, "show.json", conn: conn, episode: episode, trends: trends
    end
  end
end
