defmodule CastleWeb.API.RankController do
  use CastleWeb, :controller

  alias Castle.Rollup.Query.Ranks, as: Ranks

  @redis Application.get_env(:castle, :redis)

  def index(%{assigns: %{podcast: podcast, interval: intv, group: group}} = conn, _params) do
  end

  def index(%{assigns: %{episode: episode, interval: intv, group: group}} = conn, _params) do
  end
end
