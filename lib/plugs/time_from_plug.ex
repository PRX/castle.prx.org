defmodule Castle.Plugs.TimeFrom do
  import Plug.Conn

  def init(default), do: default

  def call(%{params: %{"from" => from_dtim}} = conn, _default) when is_bitstring(from_dtim) do
    case parse_dtim(from_dtim) do
      {:ok, dtim} ->
        assign conn, :time_from, dtim
      {:error, _err} ->
        conn
        |> send_resp(400, "Bad from param: must be a valid ISO8601 date")
        |> halt()
    end
  end

  def call(conn, _default) do
    conn
    |> send_resp(400, "Missing required param: from")
    |> halt()
  end

  defp parse_dtim(dtim_string) do
    if String.length(dtim_string) == 10 do
      Timex.parse(dtim_string, "{YYYY}-{0M}-{0D}")
    else
      Timex.parse(dtim_string, "{ISO:Extended}")
    end
  end
end
