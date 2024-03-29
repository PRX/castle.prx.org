defmodule BigQuery.Base.HTTP do
  @timeout 45000
  @bq_base "https://bigquery.googleapis.com/bigquery/v2"
  @bq_upload_base "https://bigquery.googleapis.com/upload/bigquery/v2"
  @bq_upload_type "uploadType=multipart"
  @options [{:timeout, @timeout}, {:recv_timeout, @timeout}]
  @httpoison NewRelic.Instrumented.HTTPoison

  def get(path) do
    case get_token() do
      {:ok, token} ->
        request(:get, url_for(path), token)

      {:error, error} ->
        raise error
    end
  end

  def get(params, "" <> path), do: get(path, params)

  def get(path, params) do
    encoded = params |> Map.put("timeoutMs", @timeout) |> URI.encode_query()
    get("#{path}?#{encoded}")
  end

  def post(body, "" <> path), do: post(path, body)

  def post(path, body) do
    case get_token() do
      {:ok, token} ->
        request(:post, url_for(path), token, body |> Map.put("timeoutMs", @timeout))

      {:error, error} ->
        raise error
    end
  end

  def upload(path, body, file) do
    case get_token() do
      {:ok, token} ->
        request(:post, upload_url_for(path), token, body |> Map.put("timeoutMs", @timeout), file)

      {:error, error} ->
        raise error
    end
  end

  # TODO: shared genserver to safely handle ets getting/setting
  def get_token do
    now = :os.system_time(:seconds)

    if :ets.info(__MODULE__) == :undefined do
      :ets.new(__MODULE__, [:set, :public, :named_table])
    end

    case :ets.lookup(__MODULE__, :auth_token) do
      [{_key, token, exp}] when now + 60 < exp ->
        {:ok, token}

      [{_key, _token, _exp}] ->
        :ets.delete(__MODULE__, :auth_token)
        get_token()

      _ ->
        case BigQuery.Base.Auth.get_token() do
          {:ok, token, exp} ->
            :ets.insert(__MODULE__, {:auth_token, token, exp})
            {:ok, token}

          err ->
            err
        end
    end
  end

  defp url_for(path) do
    "#{@bq_base}/projects/#{Env.get(:bq_project_id)}/#{path}"
  end

  defp upload_url_for(path) do
    "#{@bq_upload_base}/projects/#{Env.get(:bq_project_id)}/#{path}?#{@bq_upload_type}"
  end

  defp request(method, url, token) do
    apply(@httpoison, method, [url, get_headers(token), @options])
    |> decode_response()
  end

  defp request(method, url, token, body) do
    {:ok, encoded_body} = Poison.encode(body)

    apply(@httpoison, method, [url, encoded_body, get_headers(token, true), @options])
    |> decode_response()
  end

  defp request(method, url, token, body, file_string) do
    {:ok, encoded_body} = Poison.encode(body)

    parts = [
      {"json", encoded_body, ["content-type": "application/json"]},
      {"file", :zlib.gzip(file_string), ["content-type": "application/gzip"]}
    ]

    headers = [{"Content-type", "multipart/form-data"} | get_headers(token)]

    apply(@httpoison, method, [url, {:multipart, parts}, headers, @options])
    |> decode_response()
  end

  defp get_headers(token, true), do: [{"Content-type", "application/json"} | get_headers(token)]

  defp get_headers(token),
    do: [{"Authorization", "Bearer #{token}"}, {"Accept", "application/json"}]

  defp decode_response({:ok, %HTTPoison.Response{status_code: 200, body: json}}) do
    JOSE.decode(json)
  end

  defp decode_response({:ok, %HTTPoison.Response{status_code: code, body: json}}) do
    msg = JOSE.decode(json)["error"]["message"]

    if msg do
      raise "BigQuery #{code} - #{msg}"
    else
      raise "BiqQuery #{code}"
    end
  end

  defp decode_response({:error, error}) do
    raise HTTPoison.Error.message(error)
  end
end
