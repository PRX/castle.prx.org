defmodule PrxAuth.Plug do
  import Plug.Conn

  def init(default), do: default

  def call(conn, iss: iss, required: reqd) do
    if Map.get(conn, :skip_prx_auth_during_tests) do
      conn
    else
      cert = PrxAuth.Certificate.fetch(id_url(iss))
      token = conn |> get_req_header("authorization") |> get_bearer_auth()
      case PrxAuth.Token.verify(cert, iss, token) do
        {:ok, claims} -> Map.put(conn, :prx_user, PrxAuth.User.unpack(claims))
        {:bad_issuer} -> unauthorized(conn, reqd)
        {:no_token} -> unauthorized(conn, reqd)
        {_any} -> unauthorized(conn, true)
      end
    end
  end
  def call(conn, iss: iss), do: call(conn, iss: iss, required: true)
  def call(conn, required: reqd), do: call(conn, iss: Env.get(:id_host), required: reqd)
  def call(conn, _defaults), do: call(conn, iss: Env.get(:id_host), required: true)

  def unauthorized(conn, false), do: conn
  def unauthorized(conn, true) do
    conn
    |> send_resp(401, "Unauthorized")
    |> halt()
  end

  defp get_bearer_auth(["Bearer " <> auth]), do: auth
  defp get_bearer_auth(_auth), do: nil

  defp id_url(host) do
    cond do
      host =~ ~r/^http/ -> host
      host =~ ~r/\.org|\.tech/ -> "https://#{host}/api/v1/certs"
      true -> "http://#{host}/api/v1/certs"
    end
  end
end
