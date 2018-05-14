defmodule Castle.Plugs.Interval.TimeFrom do

  def parse(%{params: %{"from" => from_dtim}}) when is_bitstring(from_dtim) do
    case parse_dtim(from_dtim) do
      {:ok, dtim} -> {:ok, Timex.Timezone.convert(dtim, :utc)}
      {:error, _err} -> {:error, "Bad from param: must be a valid ISO8601 date"}
    end
  end
  def parse(_conn), do: {:error, "Missing required param: from"}

  defp parse_dtim(dtim_string) do
    format = case String.length(dtim_string) do
      8 -> "{YYYY}{0M}{0D}"
      10 -> "{YYYY}-{0M}-{0D}"
      _ -> "{ISO:Extended}"
    end
    Timex.parse(dtim_string, format)
  end
end
