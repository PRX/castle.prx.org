defmodule CastleWeb.API.RootController do
  use CastleWeb, :controller

  def index(conn, _params) do
    render conn, "index.json", conn: conn
  end
end
