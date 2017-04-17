defmodule Castle.Plugs.BasicAuth do
  import Plug.Conn

  def init(default), do: default

  def call(conn, user: nil, pass: nil), do: conn
  def call(conn, user: user, pass: pass) do
    authd = conn
    |> get_req_header("authorization")
    |> get_basic_auth()
    |> is_authorized?(user, pass)

    if authd do
      conn
    else
      conn |> send_resp(401, "Unauthorized") |> halt()
    end
  end

  def get_basic_auth(["Basic " <> auth]), do: auth
  def get_basic_auth(_auth), do: nil

  def is_authorized?(basic_auth_hash, user, pass) do
    basic_auth_hash == Base.encode64("#{user}:#{pass}")
  end
end
