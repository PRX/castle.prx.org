defmodule CastleWeb.RedirectController do
  use CastleWeb, :controller

  import CastleWeb.Router.Helpers

  def index(conn, _params) do
    redirect conn, to: api_root_path(conn, :index)
  end
end
