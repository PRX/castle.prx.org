require IEx

defmodule BigQuery.Base do

  @timeout 30000
  @bq_base "https://www.googleapis.com/bigquery/v2"
  @options [{:timeout, @timeout}, {:recv_timeout, @timeout}]

  def get(path) do
    case get_token() do
      {:ok, token} ->
        request(:get, url_for(path), token)
      {:error, error} ->
        raise error
    end
  end

  def post(path, body) do
    case get_token() do
      {:ok, token} ->
        request(:post, url_for(path), token, body |> Map.put("timeoutMs", @timeout))
      {:error, error} ->
        raise error
    end
  end

  defp get_token do
    # TODO: cache this token
    BigQuery.Auth.get_token
  end

  defp url_for(path) do
    "#{@bq_base}/projects/#{Env.get(:bq_project_id)}/#{path}"
  end

  defp request(method, url, token) do
    apply(HTTPoison, method, [url, get_headers(token), @options])
    |> parse_response()
  end

  defp request(method, url, token, body) do
    {:ok, encoded_body} = Poison.encode(body)
    apply(HTTPoison, method, [url, encoded_body, get_headers(token, true), @options])
    |> parse_response()
  end

  defp get_headers(token, true), do: [{"Content-type", "application/json"} | get_headers(token)]
  defp get_headers(token), do: [{"Authorization", "Bearer #{token}"},
                               {"Accept", "application/json"}]

  defp parse_response({:ok, %HTTPoison.Response{status_code: 200, body: json}}) do
    data = JOSE.decode(json)
    parse_rows(data["rows"], data["schema"]["fields"])
  end
  defp parse_response({:ok, %HTTPoison.Response{status_code: code, body: json}}) do
    raise JOSE.decode(json)["error"] || "Error: got #{code}"
  end
  defp parse_response({:error, error}) do
    raise HTTPoison.Error.message(error)
  end

  defp parse_rows([row | rest], schema) do
    [
      row["f"] |> parse_columns(schema) |> Enum.into(%{})
    ] ++ parse_rows(rest, schema)
  end
  defp parse_rows([], _schema), do: []

  def parse_columns([column | rest], [%{"name" => name, "type" => type} | schema]) do
    [{
      String.to_atom(name),
      Map.get(column, "v") |> parse_value(type)
    }] ++ parse_columns(rest, schema)
  end
  def parse_columns([], []), do: []

  def parse_value(value, type) do
    case {type, value} do
      {"STRING", _} ->
        value
      {"BOOLEAN", "true"} ->
        true
      {"BOOLEAN", _} ->
        false
      {"INTEGER", _} ->
        String.to_integer(value)
      {"TIMESTAMP", _} ->
        {:ok, dtim} = String.to_float(value) |> round |> div(1000) |> DateTime.from_unix
        dtim
    end
  end

end
