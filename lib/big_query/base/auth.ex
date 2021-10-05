defmodule BigQuery.Base.Auth do
  @auth_scopes [
    "https://www.googleapis.com/auth/bigquery.readonly",
    "https://www.googleapis.com/auth/bigquery"
  ]
  @token_uri "https://www.googleapis.com/oauth2/v3/token"

  def get_token(timeout \\ 3600) do
    now = :os.system_time(:seconds)
    exp = now + timeout
    email = Env.get(:bq_client_email)
    key = Env.get(:bq_private_key)

    email
    |> assemble_claims(now, exp)
    |> sign_claims(key)
    |> build_form()
    |> BigQuery.Base.AuthRequest.post_form(@token_uri)
    |> handle_response(exp)
  end

  def assemble_claims(client_email, now, expires) do
    %{
      "iss" => client_email,
      "scope" => @auth_scopes |> Enum.join(" "),
      "aud" => @token_uri,
      "exp" => expires,
      "iat" => now
    }
  end

  def sign_claims(claims, private_key) do
    jwk = JOSE.JWK.from_pem(private_key)
    encoded_claims = JOSE.encode(claims)
    header = %{"alg" => "RS256", "typ" => "JWT"}
    jws = %{"alg" => "RS256"}

    JOSE.JWS.sign(jwk, encoded_claims, header, jws)
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  def build_form(claims) do
    {:form, [assertion: claims, grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer"]}
  end

  def handle_response({:ok, %HTTPoison.Response{status_code: 200, body: json}}, exp) do
    {:ok, JOSE.decode(json)["access_token"], exp}
  end

  def handle_response({:ok, %HTTPoison.Response{status_code: _code, body: json}}, _exp) do
    {:error, JOSE.decode(json)["error"] || "Unknown error"}
  end

  def handle_response({:error, error}, _exp) do
    {:error, HTTPoison.Error.message(error)}
  end
end

defmodule BigQuery.Base.AuthRequest do
  @httpoison NewRelic.Instrumented.HTTPoison

  def post_form(form, url) do
    headers = [{"content-type", "application/x-www-form-urlencoded"}]
    @httpoison.post(url, form, headers)
  end
end
