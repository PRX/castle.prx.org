require IEx

defmodule BigQuery.Base do

  @bq_base "https://www.googleapis.com/bigquery/v2"
  @options [{:timeout, 30000}, {:recv_timeout, 30000}]

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
        request(:post, url_for(path), token, body)
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
    JOSE.decode(json) |> Map.get("rows") |> parse_rows()
  end
  defp parse_response({:ok, %HTTPoison.Response{status_code: code, body: json}}) do
    raise JOSE.decode(json)["error"] || "Error: got #{code}"
  end
  defp parse_response({:error, error}) do
    raise HTTPoison.Error.message(error)
  end

  defp parse_rows([row | rest]) do
    parse_columns(row["f"]) ++ parse_rows(rest)
  end
  defp parse_rows([]), do: []

  def parse_columns([column | rest]) do
    [Map.get(column, "v")] ++ parse_columns(rest)
  end
  def parse_columns([]), do: []

end
