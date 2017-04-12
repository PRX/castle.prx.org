defmodule Castle.RedirectController do
  use Castle.Web, :controller

  import Castle.Router.Helpers

  def index(conn, _params) do
    redirect conn, to: api_root_path(conn, :index)
  end
end
