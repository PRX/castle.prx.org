defmodule CastleWeb.API.PodcastView do
  use CastleWeb, :view

  @limit 100

  def render("index.json", %{conn: conn, podcasts: podcasts, meta: meta}) do
    limit = Enum.min [@limit, length(podcasts)]
    items = podcasts |> Enum.slice(0, limit) |> Enum.map(&(podcast_json(&1, nil, conn)))
    %{
      count: limit,
      total: length(podcasts),
      _embedded: %{
        "prx:items": items
      },
      meta: meta,
    }
  end

  def render("show.json", %{conn: conn, podcast: podcast, trends: trends, meta: meta}) do
    podcast_json(podcast, trends, conn) |> Map.put(:meta, meta)
  end

  defp podcast_json(%{feeder_podcast: id, count: count}, trends, conn) do
    %{
      id: id,
      name: id,
      downloads: trends_json(count, trends),
      _links: %{
        self: %{
          href: api_podcast_path(conn, :show, id),
          templated: true,
        },
        alternate: %{
          href: "https://feeder.prx.org/api/v1/podcasts/#{id}"
        },
        "prx:downloads": %{
          href: api_podcast_download_path(conn, :index, id) <> "{?interval,from,to,group,grouplimit}",
          templated: true,
        },
        "prx:impressions": %{
          href: api_podcast_impression_path(conn, :index, id) <> "{?interval,from,to,group,grouplimit}",
          templated: true,
        },
      }
    }
  end

  defp trends_json(total_count, nil), do: %{total: total_count}
  defp trends_json(total_count, trends) do
    %{
      total: total_count,
      today: Map.get(trends, :today, 0),
      yesterday: Map.get(trends, :yesterday, 0),
      this7days: Map.get(trends, :this7, 0),
      previous7days: Map.get(trends, :last7, 0),
    }
  end
end
