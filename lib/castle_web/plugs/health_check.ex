defmodule CastleWeb.Plugs.HealthCheck do
  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{request_path: "/health"} = conn, _opts) do
    NewRelic.ignore_transaction()

    conn
    |> put_resp_header("content-type", "text/plain; charset=utf-8")
    |> send_resp(200, "okay")
    |> halt()
  end

  def call(conn, _opts), do: conn
end
