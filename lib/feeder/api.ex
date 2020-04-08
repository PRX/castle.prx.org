defmodule Feeder.Api do
  use Memoize

  @per 200
  @max_pages 4
  @ever "1970-01-01"

  defmemo root(), expires_in: :timer.seconds(300) do
    Env.get(:feeder_host)
    |> PrxAccess.root(
      account: "*",
      id_host: Env.get(:id_host),
      client_id: Env.get(:client_id),
      client_secret: Env.get(:client_secret)
    )
    |> PrxAccess.follow("/api/v1/authorization")
  end

  def podcasts(since \\ @ever) do
    root()
    |> PrxAccess.follow("prx:podcasts", since: format(since), per: @per)
    |> get_item_pages([], 1)
  end

  def episodes(since \\ @ever) do
    root()
    |> PrxAccess.follow("prx:episodes", since: format(since), per: @per)
    |> get_item_pages([], 1)
  end

  defp get_item_pages({:ok, doc}, acc, depth) do
    items = acc ++ get_items(doc)
    total = Map.get(doc.attributes, "total", length(items))

    cond do
      !PrxAccess.link?(doc, "next") -> {:ok, total, items}
      depth + 1 > @max_pages -> {:partial, total, items}
      true -> PrxAccess.follow(doc, "next") |> get_item_pages(items, depth + 1)
    end
  end

  defp get_item_pages(err, _, _), do: err

  defp get_items(doc) do
    case PrxAccess.follow(doc, "prx:items") do
      {:ok, docs} -> docs
      _ -> []
    end
  end

  defp format("" <> dtim_str), do: dtim_str

  defp format(dtim) do
    {:ok, dtim_str} = Timex.format(dtim, "{ISO:Extended:Z}")
    dtim_str
  end
end
