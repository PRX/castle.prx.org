defmodule Castle.API.EpisodeView do
  use Castle.Web, :view

  def render("index.json", %{conn: conn, episodes: episodes, meta: meta}) do
    %{
      count: length(episodes),
      total: length(episodes),
      _embedded: %{
        "prx:items": Enum.map(episodes, fn(p) -> episode_json(p, conn) end)
      },
      meta: meta,
    }
  end

  def render("show.json", %{conn: conn, episode: episode, meta: meta}) do
    episode_json(episode, conn) |> Map.put(:meta, meta)
  end

  defp episode_json(episode, conn) do
    %{
      guid: episode.feeder_episode,
      name: episode.feeder_episode,
      downloads: %{
        past1: episode.downloads_past1 || 0,
        past12: episode.downloads_past12 || 0,
        past24: episode.downloads_past24 || 0,
        past48: episode.downloads_past48 || 0,
      },
      impressions: %{
        past1: episode.impressions_past1 || 0,
        past12: episode.impressions_past12 || 0,
        past24: episode.impressions_past24 || 0,
        past48: episode.impressions_past48 || 0,
      },
      _links: %{
        self: %{
          href: api_episode_path(conn, :show, episode.feeder_episode),
          templated: true,
        },
        alternate: %{
          href: "http://feeder.prx.org/api/v1/episodes/#{episode.feeder_episode}"
        },
        "prx:downloads": %{
          href: api_episode_download_path(conn, :index, episode.feeder_episode) <> "{?interval,from,to,group,grouplimit}",
          templated: true,
        },
        "prx:impressions": %{
          href: api_episode_impression_path(conn, :index, episode.feeder_episode) <> "{?interval,from,to,group,grouplimit}",
          templated: true,
        },
      }
    }
  end
end
