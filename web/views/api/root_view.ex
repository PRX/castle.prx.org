defmodule Porter.API.RootView do
  use Porter.Web, :view

  def render("index.json", %{conn: conn}) do
    %{
      version: "v1",
      _links: %{
        self: %{
          href: api_root_path(conn, :index),
          profile: "http://meta.prx.org/model/api",
        },
        profile: %{
          href: "http://meta.prx.org/model/api",
        },
        "prx:podcasts": [%{
          title: "Get a paged collection of podcasts",
          profile: "http://meta.prx.org/model/metrics/podcast",
          href: api_podcast_path(conn, :index) <> "{?page,per}",
          templated: true,
        }],
        "prx:podcast": [%{
          title: "Get metrics for a single podcast",
          profile: "http://meta.prx.org/model/metrics/podcast",
          href: api_podcast_path(conn, :show, "") <> "{id}",
          templated: true,
        }],
        "prx:episodes": [%{
          title: "Get a paged collection of podcast episodes",
          profile: "http://meta.prx.org/model/metrics/episode",
          href: api_episode_path(conn, :index) <> "{?page,per}",
          templated: true,
        }],
        "prx:episode": [%{
          title: "Get metrics for a single podcast episode",
          profile: "http://meta.prx.org/model/metrics/episode",
          href: api_episode_path(conn, :show, "") <> "{guid}",
          templated: true,
        }],
        "prx:downloads": [
          %{
            rel: "podcast",
            href: api_podcast_path(conn, :downloads, "") <> "{id}{?interval,start,end}",
            templated: true,
          },
          %{
            rel: "episode",
            href: api_episode_path(conn, :downloads, "") <> "{guid}{?interval,start,end}",
            templated: true,
          },
        ],
        "prx:impressions": [
          %{
            rel: "podcast",
            href: api_podcast_path(conn, :impressions, "") <> "{id}{?interval,start,end}",
            templated: true,
          },
          %{
            rel: "episode",
            href: api_episode_path(conn, :impressions, "") <> "{guid}{?interval,start,end}",
            templated: true,
          },
        ],
      }
    }
  end

end
