defmodule BigQuery.Auth do

  @auth_scopes [
    "https://www.googleapis.com/auth/bigquery.readonly",
    "https://www.googleapis.com/auth/bigquery"
  ]
  @token_uri "https://www.googleapis.com/oauth2/v3/token"

  def get_token(timeout \\ 3600) do
    Env.get(:bq_client_email)
    |> assemble_claims(timeout)
    |> sign_claims(Env.get(:bq_private_key))
    |> send_request
  end

  defp assemble_claims(client_email, timeout) do
    iat = :os.system_time(:seconds)
    exp = iat + timeout
    %{
      "iss" => client_email,
      "scope" => @auth_scopes |> Enum.join(" "),
      "aud" => @token_uri,
      "exp" => exp,
      "iat" => iat
    }
  end

  defp sign_claims(claims, private_key) do
    jwk = JOSE.JWK.from_pem(private_key)
    encoded_claims = JOSE.encode(claims)
    header = %{"alg" => "RS256", "typ" => "JWT"}
    jws = %{"alg" => "RS256"}
    JOSE.JWS.sign(jwk, encoded_claims, header, jws)
    |> JOSE.JWS.compact
    |> elem(1)
  end

  defp send_request(claims) do
    headers = %{"Content-type" => "application/x-www-form-urlencoded"}
    form = {:form, [assertion: claims, grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer"]}
    case HTTPoison.post(@token_uri, form, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: json}} ->
        {:ok, JOSE.decode(json)["access_token"]}
      {:ok, %HTTPoison.Response{status_code: _code, body: json}} ->
        {:error, JOSE.decode(json)["error"] || "Unknown error"}
      {:error, error} ->
        {:error, HTTPoison.Error.message(error)}
    end
  end

end
