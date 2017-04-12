defmodule Castle.API.RootController do
  use Castle.Web, :controller

  def index(conn, _params) do
    render conn, "index.json", conn: conn
  end
end
