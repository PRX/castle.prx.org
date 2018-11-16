defmodule CastleWeb.API.RootView do
  use CastleWeb, :view

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
          href: api_podcast_path(conn, :index) <> "{?page,per,search}",
          templated: true,
        }],
        "prx:podcast": [%{
          title: "Get metrics for a single podcast",
          profile: "http://meta.prx.org/model/metrics/podcast",
          href: fix_path(api_podcast_path(conn, :show, "{id}")),
          templated: true,
        }],
        "prx:episodes": [%{
          title: "Get a paged collection of podcast episodes",
          profile: "http://meta.prx.org/model/metrics/episode",
          href: api_episode_path(conn, :index) <> "{?page,per,search}",
          templated: true,
        }],
        "prx:episode": [%{
          title: "Get metrics for a single podcast episode",
          profile: "http://meta.prx.org/model/metrics/episode",
          href: fix_path(api_episode_path(conn, :show, "{guid}")),
          templated: true,
        }],
        "prx:podcast-downloads": [%{
          href: fix_path(api_podcast_download_path(conn, :index, "{id}") <> "{?interval,from,to}"),
          templated: true,
        }],
        "prx:podcast-ranks": [%{
          href: fix_path(api_podcast_rank_path(conn, :index, "{id}") <> "{?interval,from,to,group,limit,filters}"),
          templated: true,
        }],
        "prx:podcast-totals": [%{
          href: fix_path(api_podcast_total_path(conn, :index, "{id}") <> "{?from,to,group,filters}"),
          templated: true,
        }],
        "prx:episode-downloads": [%{
          href: fix_path(api_episode_download_path(conn, :index, "{guid}") <> "{?interval,from,to}"),
          templated: true,
        }],
        "prx:episode-ranks": [%{
          href: fix_path(api_episode_rank_path(conn, :index, "{guid}") <> "{?interval,from,to,group,limit,filters}"),
          templated: true,
        }],
        "prx:episode-totals": [%{
          href: fix_path(api_episode_total_path(conn, :index, "{id}") <> "{?from,to,group,filters}"),
          templated: true,
        }],
      }
    }
  end

  defp fix_path(path) do
    path |> String.replace("%7B", "{") |> String.replace("%7D", "}")
  end
end
