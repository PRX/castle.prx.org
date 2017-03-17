defmodule Porter.PageController do
  use Porter.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
