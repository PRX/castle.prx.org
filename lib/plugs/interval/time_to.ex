defmodule Castle.Plugs.Interval.TimeTo do

  def parse(%{params: %{"to" => to_dtim}}) when is_bitstring(to_dtim) do
    case parse_dtim(to_dtim) do
      {:ok, dtim} -> {:ok, Timex.Timezone.convert(dtim, :utc)}
      {:error, _err} -> {:error, "Bad to param: must be a valid ISO8601 date"}
    end
  end
  def parse(_conn) do
    {:ok, Timex.now |> Timex.beginning_of_day |> Timex.shift(days: 1)}
  end

  defp parse_dtim(dtim_string) do
    case String.length(dtim_string) do
      8 -> parse_dtim(dtim_string, "{YYYY}{0M}{0D}", true)
      10 -> parse_dtim(dtim_string, "{YYYY}-{0M}-{0D}", true)
      _ -> parse_dtim(dtim_string, "{ISO:Extended}", false)
    end
  end
  defp parse_dtim(dtim_string, format, end_of_day) do
    case Timex.parse(dtim_string, format) do
      {:ok, dtim} ->
        if end_of_day do
          {:ok, Timex.end_of_day(dtim) |> Timex.to_unix() |> Timex.from_unix()}
        else
          {:ok, dtim}
        end
      other ->
        other
    end
  end
end
