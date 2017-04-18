defmodule Castle.Plugs.BasicAuth do
  import Plug.Conn

  def init(default), do: default

  def call(conn, user: user, pass: pass) do
    authd = conn
    |> get_req_header("authorization")
    |> get_basic_auth()
    |> is_authorized?(user, pass)

    if authd do
      conn
    else
      conn
      |> put_resp_header("www-authenticate", "Basic realm=\"You shall not pass!\"")
      |> send_resp(401, "Unauthorized")
      |> halt()
    end
  end
  def call(conn, _defaults) do
    call conn, user: Env.get(:basic_auth_user), pass: Env.get(:basic_auth_pass)
  end

  defp get_basic_auth(["Basic " <> auth]), do: auth
  defp get_basic_auth(_auth), do: nil

  defp is_authorized?(_hash, nil, nil), do: true
  defp is_authorized?(basic_auth_hash, user, pass) do
    basic_auth_hash == Base.encode64("#{user}:#{pass}")
  end
end
