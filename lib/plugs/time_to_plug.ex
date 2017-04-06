defmodule Porter.Plugs.TimeTo do
  import Plug.Conn

  # if no end date is set, just use this many seconds into the future
  @buffer_seconds 60

  def init(default), do: default

  def call(%{params: %{"to" => to_dtim}} = conn, _default) when is_bitstring(to_dtim) do
    case parse_dtim(to_dtim) do
      {:ok, dtim} ->
        assign conn, :time_to, dtim
      {:error, _err} ->
        send_resp conn, 400, "Bad to param: must be a valid ISO8601 date"
    end
  end

  def call(conn, _default) do
    assign conn, :time_to, Timex.shift(Timex.now, seconds: @buffer_seconds)
  end

  defp parse_dtim(dtim_string) do
    if String.length(dtim_string) == 10 do
      Timex.parse(dtim_string, "{YYYY}-{0M}-{0D}")
    else
      Timex.parse(dtim_string, "{ISO:Extended}")
    end
  end
end
