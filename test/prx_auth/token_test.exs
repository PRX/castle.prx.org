defmodule PrxAuth.TokenTest do
  use ExUnit.Case, async: true

  import PrxAuth.Token

  @support Path.expand("#{__DIR__}/../support")
  @jwk JOSE.JWK.from_pem_file("#{@support}/test_key.pem")
  @cert File.read("#{@support}/test_cert.pem") |> elem(1)
  @test_claims %{
    "sub": 3,
    "exp": 3600,
    "iat": :os.system_time(:seconds),
    "token_type": "bearer",
    "scope": "profile email address phone read-private",
    "aur": %{"123456" => "admin"},
    "iss": "id.prx.org",
  }

  def claim(claims) do
    signed = JOSE.JWT.sign(@jwk, claims)
    {_alg, jwt} = JOSE.JWS.compact(signed)
    jwt
  end

  test "verifies" do
    assert {:ok, claims} = verify(@cert, "id.prx.org", claim(@test_claims))
    assert claims["iss"] == "id.prx.org"
    assert claims["aur"]["123456"] == "admin"
  end

  test "verifies lack of token" do
    assert {:no_token} = verify(@cert, "id.prx.org", nil)
  end

  test "verifies invalid jwts" do
    assert {:invalid} = verify(@cert, "id.prx.org", "foobar")
  end

  test "verifies issuer mismatch" do
    assert {:bad_issuer} = verify(@cert, "id2.prx.org", claim(@test_claims))
  end

  test "verifies bad certs" do
    assert {:bad_cert} = verify("foobar", "id.prx.org", claim(@test_claims))
  end

  test "verifies bad jwts" do
    assert {:failed} = verify(@cert, "id.prx.org", claim(@test_claims) <> "1")
  end

  test "verifies expired jwts" do
    expired = %{"iss": "id.prx.org", "exp": 3600, "iat": :os.system_time(:seconds) - 4000}
    assert {:expired} = verify(@cert, "id.prx.org", claim(expired))
  end

  test "validates jwt tokens" do
    assert valid?(claim(%{"iss" => "foo"})) == true
    assert valid?("foobar") == false
  end

  test "detects issuer" do
    assert issuer(claim(%{"iss" => "foo"})) == "foo"
    assert issuer(claim(%{"iss" => "bar"})) == "bar"
    assert issuer(claim(%{})) == nil
  end

  test "detects expiration" do
    now = :os.system_time(:seconds)
    assert expired?(%{}) == false
    assert expired?(%{"iat" => now - 10}) == false
    assert expired?(%{"exp" => now - 100}) == true
    assert expired?(%{"exp" => now + 10}) == false
    assert expired?(%{"iat" => now - 10, "exp" => 5}) == true
    assert expired?(%{"iat" => now - 10, "exp" => 15}) == false
  end
end
