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
    format = case String.length(dtim_string) do
      8 -> "{YYYY}{0M}{0D}"
      10 -> "{YYYY}-{0M}-{0D}"
      _ -> "{ISO:Extended}"
    end
    Timex.parse(dtim_string, format)
  end
end
