defmodule Castle.API.EpisodeView do
  use Castle.Web, :view

  @limit 100

  def render("index.json", %{conn: conn, episodes: episodes, meta: meta}) do
    limit = Enum.min [@limit, length(episodes)]
    items = episodes |> Enum.slice(0, limit) |> Enum.map(&(episode_json(&1, conn)))
    %{
      count: limit,
      total: length(episodes),
      _embedded: %{
        "prx:items": items
      },
      meta: meta,
    }
  end

  def render("show.json", %{conn: conn, episode: episode, meta: meta}) do
    episode_json(episode, conn)
    |> put_podcast_link(conn, episode)
    |> Map.put(:meta, meta)
  end

  defp episode_json(%{feeder_episode: guid, count: count}, conn) do
    %{
      guid: guid,
      name: guid,
      downloads: %{
        total: count,
      },
      _links: %{
        self: %{
          href: api_episode_path(conn, :show, guid),
          templated: true,
        },
        alternate: %{
          href: "http://feeder.prx.org/api/v1/episodes/#{guid}"
        },
        "prx:downloads": %{
          href: api_episode_download_path(conn, :index, guid) <> "{?interval,from,to,group,grouplimit}",
          templated: true,
        },
        "prx:impressions": %{
          href: api_episode_impression_path(conn, :index, guid) <> "{?interval,from,to,group,grouplimit}",
          templated: true,
        },
      }
    }
  end

  defp put_podcast_link(json, conn, %{feeder_podcast: id}) do
    put_in json, [:_links, "prx:podcast"], %{href: api_podcast_path(conn, :show, id)}
  end
  defp put_podcast_link(json, _conn, _episode), do: json
end
