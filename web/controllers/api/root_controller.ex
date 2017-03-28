defmodule Porter.API.RootController do
  use Porter.Web, :controller

  def index(conn, _params) do
    render conn, "index.json", conn: conn
  end
end
