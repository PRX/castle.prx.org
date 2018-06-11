defmodule CastleWeb.API.RankController do
  use CastleWeb, :controller

  def index(%{assigns: %{podcast: podcast, interval: intv, group: group}} = conn, _params) do
    {ranks, raw_data} = group.ranks.podcast(podcast.id, intv, group)
    data = bucketize_groups(ranks, raw_data, intv)
    render conn, "rank.json", id: podcast.id, interval: intv, group: group, ranks: ranks, downloads: data
  end

  def index(%{assigns: %{episode: episode, interval: intv, group: group}} = conn, _params) do
    {ranks, raw_data} = group.ranks.episode(episode.id, intv, group)
    data = bucketize_groups(ranks, raw_data, intv)
    render conn, "rank.json", id: episode.id, interval: intv, group: group, ranks: ranks, downloads: data
  end
end
