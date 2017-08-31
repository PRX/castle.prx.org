defmodule Castle.API.PodcastView do
  use Castle.Web, :view

  @limit 100

  def render("index.json", %{conn: conn, podcasts: podcasts, meta: meta}) do
    limit = Enum.min [@limit, length(podcasts)]
    items = podcasts |> Enum.slice(0, limit) |> Enum.map(&(podcast_json(&1, conn)))
    %{
      count: limit,
      total: length(podcasts),
      _embedded: %{
        "prx:items": items
      },
      meta: meta,
    }
  end

  def render("show.json", %{conn: conn, podcast: podcast, meta: meta}) do
    podcast_json(podcast, conn) |> Map.put(:meta, meta)
  end

  defp podcast_json(%{feeder_podcast: id, count: count}, conn) do
    %{
      id: id,
      name: id,
      downloads: %{
        total: count,
      },
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
end
