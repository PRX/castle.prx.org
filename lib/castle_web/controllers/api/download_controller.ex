defmodule CastleWeb.API.DownloadController do
  use CastleWeb, :controller

  alias Castle.Rollup.Query.Downloads, as: Downloads

  @redis Application.get_env(:castle, :redis)

  plug Castle.Plugs.ParseInt, "podcast_id"

  def index(%{assigns: %{interval: intv}} = conn, %{"podcast_id" => id}) do
    raw_data = case @redis.podcast_increments(id, intv) do
      {nil, _} -> Downloads.podcast(id, intv)
      {cached, nil} -> cached
      {cached, new_intv} -> Downloads.podcast(id, new_intv) ++ cached
    end
    data = bucketize(raw_data, intv)
    render conn, "download.json", id: id, interval: intv, downloads: data
  end

  def index(%{assigns: %{interval: intv}} = conn, %{"episode_guid" => id}) do
    raw_data = case @redis.episode_increments(id, intv) do
      {nil, _} -> Downloads.episode(id, intv)
      {cached, nil} -> cached
      {cached, new_intv} -> Downloads.episode(id, new_intv) ++ cached
    end
    data = bucketize(raw_data, intv)
    render conn, "download.json", id: id, interval: intv, downloads: data
  end
end
