defmodule BigQuery.Base.QueryParams do

  def parameterize(params \\ %{}) do
    params
    |> Map.to_list
    |> parse_param
  end

  defp parse_param([{key, value} | rest]) do
    [
      %{
        name: key,
        parameterValue: %{value: value},
        parameterType: %{type: guess_type(value)},
      }
    ] ++ parse_param(rest)
  end
  defp parse_param(_), do: []

  defp guess_type(%DateTime{}), do: "TIMESTAMP"
  defp guess_type(val) when is_integer(val), do: "INT64"
  defp guess_type(val) when is_float(val), do: "FLOAT64"
  defp guess_type(val) when is_boolean(val), do: "BOOL"
  defp guess_type(_), do: "STRING"
end
