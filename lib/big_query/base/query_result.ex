defmodule BigQuery.Base.QueryResult do

  def from_response(data) do
    {
      parse_rows(data["rows"], data["schema"]["fields"]),
      parse_meta(data),
    }
  end

  defp parse_meta(data) do
    %{
      cached: data |> Map.get("cacheHit", false),
      total: data |> Map.get("totalRows", "0") |> String.to_integer,
      bytes: data |> Map.get("totalBytesProcessed", "0") |> String.to_integer,
      megabytes: data |> Map.get("totalBytesProcessed", "0") |> String.to_integer |> div(1000 * 1000),
    }
  end

  defp parse_rows([row | rest], schema) do
    [
      row["f"] |> parse_columns(schema) |> Enum.into(%{})
    ] ++ parse_rows(rest, schema)
  end

  defp parse_rows(_, _schema), do: []

  defp parse_columns([column | rest], [%{"name" => name, "type" => type} | schema]) do
    [{
      String.to_atom(name),
      Map.get(column, "v") |> parse_value(type)
    }] ++ parse_columns(rest, schema)
  end

  defp parse_columns([], []), do: []

  defp parse_value(value, type) do
    case {type, value} do
      {_type, nil} ->
        nil
      {"STRING", _} ->
        value
      {"BOOLEAN", "true"} ->
        true
      {"BOOLEAN", _} ->
        false
      {"INTEGER", _} ->
        String.to_integer(value)
      {"TIMESTAMP", _} ->
        num = if String.contains?(value, "E"),
          do: String.to_float(value) |> round,
          else: String.to_integer(value)
        {:ok, dtim} = DateTime.from_unix(num)
        dtim
    end
  end

end
