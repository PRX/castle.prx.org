defmodule Feeder.Api do

  def podcasts(nil) do
    get_items("/api/v1/podcasts", %{since: "1970-01-01", per: 20})
  end
  def podcasts(since_dtim) do
    {:ok, since_str} = Timex.format(since_dtim, "{ISO:Extended:Z}")
    get_items("/api/v1/podcasts", %{since: since_str, per: 20})
  end

  def get_items(path), do: get_items(path, %{})
  def get_items(path, params) do
    case HTTPoison.get(url(path), [], params: params) do
      {:ok, %{status_code: 200, body: body}} -> parse_items(Poison.decode(body))
      {:ok, %{status_code: 404}} -> {:error, "not found"}
      {:error, %{reason: reason}} -> {:error, reason}
    end
  end

  def url(path) do
    case Env.get(:feeder_host) |> String.split(".") |> List.last() do
      ".org" -> "https://#{Env.get(:feeder_host)}/#{path}"
      ".tech" -> "https://#{Env.get(:feeder_host)}/#{path}"
      _ -> "http://#{Env.get(:feeder_host)}/#{path}"
    end
  end

  def parse_items({:ok, %{"_embedded" => %{"prx:items" => items}} = doc}) do
    items ++ rest_pages(doc)
  end
  def parse_items({:ok, _doc}), do: []

  def rest_pages(%{"_links" => %{"next" => %{"href" => href}}}), do: get_items(href)
  def rest_pages(_doc), do: []
end
