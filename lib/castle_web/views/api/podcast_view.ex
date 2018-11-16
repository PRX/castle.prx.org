defmodule CastleWeb.API.PodcastView do
  use CastleWeb, :view

  def render("index.json", %{conn: conn, podcasts: podcasts, paging: paging}) do
    %{
      count: length(podcasts),
      total: Map.get(paging, :total),
      _embedded: %{
        "prx:items": Enum.map(podcasts, &(podcast_json(&1, nil, conn)))
      },
      _links: paging_links(api_podcast_path(conn, :index), paging),
    }
  end

  def render("show.json", %{conn: conn, podcast: podcast, trends: trends}) do
    podcast_json(podcast, trends, conn)
  end

  defp podcast_json(podcast, nil, conn) do
    %{
      id: podcast.id,
      title: podcast.title,
      subtitle: podcast.subtitle,
      _links: podcast_links(conn, podcast),
    }
  end
  defp podcast_json(podcast, trends, conn) do
    podcast_json(podcast, nil, conn) |> Map.put(:downloads, trends)
  end

  defp podcast_links(conn, podcast) do
    %{
      self: %{
        href: api_podcast_path(conn, :show, podcast.id),
      },
      alternate: %{
        href: "https://feeder.prx.org/api/v1/podcasts/#{podcast.id}",
      },
      "prx:episodes": %{
        href: api_podcast_episode_path(conn, :index, podcast.id) <> "{?page,per,search}",
        templated: true,
      },
      "prx:downloads": %{
        href: api_podcast_download_path(conn, :index, podcast.id) <> "{?interval,from,to}",
        templated: true,
      },
      "prx:ranks": %{
        href: api_podcast_rank_path(conn, :index, podcast.id) <> "{?interval,from,to,group,limit,filters}",
       templated: true,
      },
      "prx:totals": %{
        href: api_podcast_total_path(conn, :index, podcast.id) <> "{?from,to,group,filters}",
        templated: true,
      },
    } |> podcast_image_link(podcast.image_url)
  end

  defp podcast_image_link(links, nil), do: links
  defp podcast_image_link(links, url), do: Map.put(links, "prx:image", %{href: url})
end
