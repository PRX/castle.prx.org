defmodule CastleWeb.API.DownloadController do
  use CastleWeb, :controller

  alias Castle.Rollup.Query.Downloads, as: Downloads

  plug Castle.Plugs.ParseInt, "podcast_id"

  def index(%{assigns: %{interval: intv}} = conn, %{"podcast_id" => id}) do
    data = Downloads.podcast(id, intv) |> bucketize(intv)
    render conn, "download.json", id: id, interval: intv, downloads: data
  end

  def index(%{assigns: %{interval: intv}} = conn, %{"episode_guid" => id}) do
    data = Downloads.episode(id, intv) |> bucketize(intv)
    render conn, "download.json", id: id, interval: intv, downloads: data
  end
end
