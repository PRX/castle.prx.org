defmodule PrxAuth.Token do

  def verify(_cert, _iss, nil), do: {:no_token}
  def verify(cert, iss, jwt) do
    jwk = JOSE.JWK.from_pem(cert)
    cond do
      !valid?(jwt) -> {:invalid}
      issuer(jwt) != iss -> {:bad_issuer}
      jwk == [] -> {:bad_cert}
      true ->
        case JOSE.JWT.verify(jwk, jwt) do
          {:error, _err} -> {:failed}
          {false, _claims, _jws} -> {:failed}
          {true, claims, _jws} ->
            if expired?(claims.fields), do: {:expired}, else: {:ok, claims.fields}
        end
    end
  end

  def valid?(jwt) do
    try do
      JOSE.JWT.peek(jwt)
      true
    rescue
      ArgumentError -> false
    end
  end

  def issuer(jwt) do
    case JOSE.JWT.peek(jwt).fields do
      %{"iss" => iss} -> iss
      _ -> nil
    end
  end

  def expired?(%{"iat" => iat, "exp" => exp}), do: :os.system_time(:seconds) > (iat + exp)
  def expired?(%{"exp" => exp}), do: :os.system_time(:seconds) > exp
  def expired?(_), do: false
end
