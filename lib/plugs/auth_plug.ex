defmodule Castle.Plugs.Auth do
  import Ecto.Query

  @fake_user_id 999999

  def init(default), do: default

  def call(conn, _opts) do
    if Mix.env == :prod do
      call_auth conn, nil
    else
      call_auth conn, Env.get(:dev_auth)
    end
  end

  def id_host, do: Env.get(:id_host)

  defp call_auth(conn, nil) do
    PrxAuth.Plug.call(conn, required: true, iss: &Castle.Plugs.Auth.id_host/0)
  end
  defp call_auth(conn, "*") do
    accounts = Castle.Repo.all(from p in Castle.Podcast, select: p.account_id,
      distinct: true, where: not is_nil(p.account_id))
    Map.put conn, :prx_user, make_user(@fake_user_id, accounts)
  end
  defp call_auth(conn, account_id) when is_integer(account_id) do
    Map.put conn, :prx_user, make_user(@fake_user_id, [account_id])
  end
  defp call_auth(conn, account_ids) do
    accounts = String.split(account_ids, ",")
    Map.put conn, :prx_user, make_user(@fake_user_id, accounts)
  end

  defp make_user(id, account_ids) do
    %PrxAuth.User{id: id, auths: make_auths(account_ids)}
  end

  defp make_auths(ids), do: make_auths ids, %{}
  defp make_auths([], auths), do: auths
  defp make_auths([id | rest], auths) do
    make_auths rest, Map.put(auths, "#{id}", %{"castle:read_private" => true})
  end
end
