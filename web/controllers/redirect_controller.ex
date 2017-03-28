defmodule Porter.RedirectController do
  use Porter.Web, :controller

  import Porter.Router.Helpers

  def index(conn, _params) do
    redirect conn, to: api_root_path(conn, :index)
  end
end
