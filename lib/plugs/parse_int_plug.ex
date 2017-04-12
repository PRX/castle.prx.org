defmodule Porter.Plugs.ParseInt do
  import Plug.Conn

  def init(default), do: default

  def call(conn, param_name) do
    if Map.has_key?(conn.params, param_name) do
      case Integer.parse(conn.params[param_name]) do
        {num, ""} ->
          conn
          |> Map.put(:params, Map.put(conn.params, param_name, num))
        _ ->
          conn
          |> send_resp(404, "#{conn.params[param_name]} is not an integer")
          |> halt()
      end
    else
      conn
    end
  end
end
