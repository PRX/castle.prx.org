defmodule Porter.API.PodcastView do
  use Porter.Web, :view

  def render("index.json", %{conn: conn, podcasts: podcasts}) do
    %{
      count: length(podcasts),
      total: length(podcasts),
      _embedded: %{
        "prx:items": Enum.map(podcasts, fn(p) -> podcast_json(p, conn) end)
      }
    }
  end

  def render("show.json", %{conn: conn, podcast: podcast}) do
    podcast_json(podcast, conn)
  end

  defp podcast_json(podcast, conn) do
    %{
      id: podcast.feeder_podcast,
      name: podcast.feeder_podcast,
      downloads: %{
        past1: podcast.downloads_past1 || 0,
        past12: podcast.downloads_past12 || 0,
        past24: podcast.downloads_past24 || 0,
        past48: podcast.downloads_past48 || 0,
      },
      impressions: %{
        past1: podcast.impressions_past1 || 0,
        past12: podcast.impressions_past12 || 0,
        past24: podcast.impressions_past24 || 0,
        past48: podcast.impressions_past48 || 0,
      },
      _links: %{
        self: %{
          href: api_podcast_path(conn, :show, podcast.feeder_podcast),
          templated: true,
        },
        alternate: %{
          href: "http://feeder.prx.org/api/v1/podcasts/#{podcast.feeder_podcast}"
        },
        "prx:downloads": %{
          href: api_podcast_download_path(conn, :index, podcast.feeder_podcast) <> "{?interval,from,to}",
          templated: true,
        },
        "prx:impressions": %{
          href: api_podcast_impression_path(conn, :index, podcast.feeder_podcast) <> "{?interval,from,to}",
          templated: true,
        },
      }
    }
  end
end
