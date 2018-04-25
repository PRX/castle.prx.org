defmodule Feeder.Api do

  @per 100
  @max_pages 4
  @ever "1970-01-01"

  def podcasts(), do: get_items("/api/v1/podcasts", %{since: @ever, per: @per})
  def podcasts(since), do: get_items("/api/v1/podcasts", %{since: format(since), per: @per})

  def episodes(), do: get_items("/api/v1/episodes", %{since: @ever, per: @per})
  def episodes(pid) when is_integer(pid), do: get_items("/api/v1/podcasts/#{pid}/episodes", %{since: @ever, per: @per})
  def episodes(since), do: get_items("/api/v1/episodes", %{since: format(since), per: @per})
  def episodes(pid, since), do: get_items("/api/v1/podcasts/#{pid}/episodes", %{since: format(since), per: @per})

  def get_items(path, params, depth \\ 1) do
    case HTTPoison.get(url(path), [], params: params) do
      {:ok, %{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, json} -> get_item_pages(json, depth)
          _any -> {:error, "invalid json from #{url(path)}"}
        end
      {:ok, %{status_code: code}} -> {:error, "got #{code} from #{url(path)}"}
      {:error, %{reason: reason}} -> {:error, reason}
    end
  end

  def url("http" <> rest), do: "http#{rest}"
  def url(path) do
    case Env.get(:feeder_host) |> String.split(".") |> List.last() do
      "org" -> "https://#{Env.get(:feeder_host)}#{path}"
      "tech" -> "https://#{Env.get(:feeder_host)}#{path}"
      _ -> "http://#{Env.get(:feeder_host)}#{path}"
    end
  end

  defp get_item_pages(%{"_embedded" => %{"prx:items" => items}} = doc, depth) do
    case next_page(doc, depth + 1) do
      {:partial, total} -> {:partial, total, items}
      {:error, err} -> {:error, err}
      {state, total, next_items} -> {state, total, items ++ next_items}
    end
  end
  defp get_item_pages(%{"total" => total}, _depth), do: {:ok, total, []}
  defp get_item_pages(_doc, _depth), do: {:ok, 0, []}

  defp next_page(%{"total" => total}, depth) when depth > @max_pages do
    {:partial, total}
  end
  defp next_page(%{"_links" => %{"next" => %{"href" => href}}}, depth) do
    get_items(href, %{}, depth)
  end
  defp next_page(%{"total" => total}, _depth) do
    {:ok, total, []}
  end

  defp format(dtim) do
    {:ok, dtim_str} = Timex.format(dtim, "{ISO:Extended:Z}")
    dtim_str
  end
end
