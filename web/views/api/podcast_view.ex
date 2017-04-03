defmodule Porter.API.PodcastView do
  use Porter.Web, :view

  def render("index.json", %{conn: conn, programs: programs}) do
    %{
      count: length(programs),
      total: length(programs),
      _embedded: %{
        "prx:items": Enum.map(programs, fn(p) -> program_json(p, conn) end)
      }
    }
  end

  def render("show.json", %{conn: conn, program: program}) do
    program_json(program, conn)
  end

  defp program_json(program, conn) do
    %{
      id: program.program,
      name: program.program,
      downloads: %{
        past1: program.downloads_past1 || 0,
        past12: program.downloads_past12 || 0,
        past24: program.downloads_past24 || 0,
        past48: program.downloads_past48 || 0,
      },
      impressions: %{
        past1: program.impressions_past1 || 0,
        past12: program.impressions_past12 || 0,
        past24: program.impressions_past24 || 0,
        past48: program.impressions_past48 || 0,
      },
      _links: %{
        self: %{
          href: api_podcast_path(conn, :show, program.program),
          templated: true,
        },
        alternate: %{
          href: "http://feeder.prx.org/api/v1/podcasts/#{program.program}"
        },
        "prx:downloads": %{
          href: api_podcast_download_path(conn, :index, program.program) <> "{?interval,timeframe}",
          templated: true,
        },
        "prx:impressions": %{
          href: api_podcast_impression_path(conn, :index, program.program) <> "{?interval,timeframe}",
          templated: true,
        },
      }
    }
  end
end
