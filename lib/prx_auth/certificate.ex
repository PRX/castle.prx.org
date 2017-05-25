defmodule PrxAuth.Certificate do
  import PrxAuth.Certificate.Cache

  @expires_in 43200
  @cert_loc "https://id.prx.org/api/v1/certs"

  @http_timeout 10000
  @http_options [{:timeout, @http_timeout}, {:recv_timeout, @http_timeout}]

  def fetch(cert_loc) do
    now = :os.system_time(:seconds)
    case cache_get(cert_loc) do
      {:found, exp, result} when exp > now -> result
      {:found, _exp, _result} -> fetch_and_set(cert_loc, now + @expires_in)
      {:not_found} -> fetch_and_set(cert_loc, now + @expires_in)
    end
  end
  def fetch(), do: fetch(@cert_loc)

  defp fetch_and_set(cert_loc, expiration) do
    case HTTPoison.get(cert_loc, [], @http_options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: json}} ->
        JOSE.decode(json) |> get_cert() |> cache_set(cert_loc, expiration)
      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        raise "Error #{code} GET #{cert_loc} - #{body}"
      {:error, error} ->
        raise HTTPoison.Error.message(error)
    end
  end

  defp get_cert(%{"certificates" => certs}), do: first_cert(Map.to_list(certs))
  defp get_cert(json), do: raise "Error no certificates in #{JOSE.encode(json)}"

  defp first_cert([{_id, cert} | _rest]), do: cert
  defp first_cert(_certificates), do: raise "Error no certificates at all"
end
