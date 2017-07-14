defmodule Castle.Plugs.Interval.TimeFrom do

  def parse(%{params: %{"from" => from_dtim}}) when is_bitstring(from_dtim) do
    case parse_dtim(from_dtim) do
      {:ok, dtim} -> {:ok, dtim}
      {:error, _err} -> {:error, "Bad from param: must be a valid ISO8601 date"}
    end
  end
  def parse(_conn), do: {:error, "Missing required param: from"}

  defp parse_dtim(dtim_string) do
    if String.length(dtim_string) == 10 do
      Timex.parse(dtim_string, "{YYYY}-{0M}-{0D}")
    else
      Timex.parse(dtim_string, "{ISO:Extended}")
    end
  end
end
