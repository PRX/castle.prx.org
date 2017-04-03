defmodule Porter.API.ImpressionController do
  use Porter.Web, :controller

  def index(conn, %{"podcast_id" => podcast_id}) do
    text conn, "Impressions for podcast #{podcast_id}"
  end

  def index(conn, %{"episode_guid" => episode_guid}) do
    text conn, "Impressions for episode #{episode_guid}"
  end
end
