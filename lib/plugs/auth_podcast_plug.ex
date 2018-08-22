defmodule Castle.Plugs.AuthPodcast do
  import Plug.Conn

  def init(default), do: default

  def call(conn, []), do: call(conn, "id")
  def call(%{params: params, prx_user: user} = conn, param_name) do
    if Map.has_key?(params, param_name) do
      get_podcast conn, params[param_name], user.auths
    else
      conn
    end
  end

  defp get_podcast(conn, podcast_id, user_auths) do
    case Castle.Repo.NewRelic.get Castle.Podcast, cast_id(podcast_id) do
      nil ->
        conn |> send_resp(404, "Podcast #{podcast_id} not found") |> halt()
      podcast ->
        if user_auths[podcast.account_id] || user_auths["#{podcast.account_id}"] do
          conn |> assign(:podcast, podcast)
        else
          conn |> send_resp(403, "You do not have access to podcast #{podcast_id}") |> halt()
        end
    end
  end

  defp cast_id(id_thing) do
    case Ecto.Type.cast(:integer, id_thing) do
      :error -> 0
      {:ok, id} -> id
    end
  end
end
