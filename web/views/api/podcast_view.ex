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

  def render("downloads.json", %{conn: conn}) do
    %{
      count: 10,
      interval: "HOUR",
      timeframe: %{
        start: "2017-03-13T10:00:00.000Z",
        end: "2017-03-13T20:00:00.000Z",
      },
      downloads: [452, 454, 682, 299, 588, 682, 1045, 58, 48, 68],
    }
  end

  defp program_json(program, conn) do
    %{
      id: 1234,
      name: program.program,
      downloads: 987654,
      impressions: program.count,
      _links: %{
        self: %{
          href: api_podcast_path(conn, :show, program.program),
          templated: true,
        },
        alternate: %{
          href: "http://feeder.prx.org/api/v1/podcasts/1234"
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
