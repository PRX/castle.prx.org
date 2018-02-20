defmodule CastleWeb.API.EpisodeView do
  use CastleWeb, :view

  @limit 100

  def render("index.json", %{conn: conn, episodes: episodes, meta: meta}) do
    limit = Enum.min [@limit, length(episodes)]
    items = episodes |> Enum.slice(0, limit) |> Enum.map(&(episode_json(&1, nil, conn)))
    %{
      count: limit,
      total: length(episodes),
      _embedded: %{
        "prx:items": items
      },
      meta: meta,
    }
  end

  def render("show.json", %{conn: conn, episode: guid, total: total, trends: trends, meta: meta}) do
    episode_json(guid, total, trends, conn) |> Map.put(:meta, meta)
  end

  defp episode_json({guid, total}, trends, conn), do: episode_json(guid, total, trends, conn)
  defp episode_json(guid, total, trends, conn) do
    %{
      guid: guid,
      name: guid,
      downloads: trends_json(total, trends),
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
