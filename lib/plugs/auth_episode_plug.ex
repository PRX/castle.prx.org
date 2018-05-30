defmodule Castle.Plugs.AuthEpisode do
  import Plug.Conn
  import Ecto.Query

  def init(default), do: default

  def call(conn, []), do: call(conn, "id")
  def call(%{params: params, prx_user: user} = conn, param_name) do
    if Map.has_key?(params, param_name) do
      get_episode conn, params[param_name], user.auths
    else
      conn
    end
  end

  defp get_episode(conn, episode_id, user_auths) do
    case get_episode_and_account(episode_id) do
      nil ->
        conn |> send_resp(404, "Episode #{episode_id} not found") |> halt()
      {episode, account_id} ->
        if user_auths[account_id] || user_auths["#{account_id}"] do
          conn |> assign(:episode, episode)
        else
          conn |> send_resp(403, "You do not have access to episode #{episode_id}") |> halt()
        end
    end
  end

  defp get_episode_and_account(id) do
    case Ecto.UUID.cast(id) do
      :error -> nil
      {:ok, uuid} ->
        Castle.Repo.one from e in Castle.Episode,
          join: p in Castle.Podcast,
          where: e.id == ^uuid and p.id == e.podcast_id,
          select: {e, p.account_id},
          limit: 1
    end
  end
end
