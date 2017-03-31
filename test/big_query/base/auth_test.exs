defmodule Porter.BigQueryBaseAuthTest do
  use Porter.BigQueryCase, async: true

  import BigQuery.Base.Auth

  @tag :external
  test "gets a google oauth token" do
    {okay, token, expires} = get_token(30)
    assert okay == :ok
    assert is_binary token
    assert String.valid? token
    assert :os.system_time(:seconds) - expires <= 30
  end

  test "assembles oauth claims" do
    claims = assemble_claims("foo@bar.gov", 10000, 10055)
    assert claims["iss"] == "foo@bar.gov"
    assert claims["scope"] =~ ~r/bigquery\.readonly/
    assert claims["aud"] =~ ~r/googleapis\.com/
    assert claims["exp"] == 10055
    assert claims["iat"] == 10000
  end

  test "builds the request form" do
    {:form, items} = build_form("some-claims-string")
    assert items[:grant_type] == "urn:ietf:params:oauth:grant-type:jwt-bearer"
  end

  test "decodes token responses" do
    resp = %HTTPoison.Response{status_code: 200, body: "{\"access_token\":\"the-token\"}"}
    assert {:ok, "the-token", 999} = handle_response({:ok, resp}, 999)
  end

  test "handles non-200 errors with messages" do
    resp = %HTTPoison.Response{status_code: 400, body: "{\"error\":\"the-error\"}"}
    assert {:error, "the-error"} = handle_response({:ok, resp}, 999)
  end

  test "handles non-200 errors without messages" do
    resp = %HTTPoison.Response{status_code: 500, body: "{}"}
    assert {:error, "Unknown error"} = handle_response({:ok, resp}, 999)
  end

  test "handles httpoison errors" do
    err = %HTTPoison.Error{reason: %{some: "thing"}}
    assert {:error, "%{some: \"thing\"}"} = handle_response({:error, err}, 999)
  end
end
