defmodule CastleWeb.API.TotalController do
  use CastleWeb, :controller

  alias Castle.Rollup.Query.Totals, as: Totals

  @redis Application.get_env(:castle, :redis)

  def index(%{assigns: %{podcast: podcast, interval: intv, group: group}} = conn, _params) do
  end

  def index(%{assigns: %{episode: episode, interval: intv, group: group}} = conn, _params) do
  end
end
