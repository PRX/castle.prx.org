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
        past1: 0,
        past12: 0,
        past24: 0,
        past48: 0,
      },
      impressions: %{
        past1: program.past1,
        past12: program.past12,
        past24: program.past24,
        past48: program.past48,
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
          href: api_podcast_path(conn, :downloads, program.program) <> "{?interval,timeframe}",
          templated: true,
        },
        "prx:impressions": %{
          href: api_podcast_path(conn, :downloads, program.program) <> "{?interval,timeframe}",
          templated: true,
        },
      }
    }
  end
end
