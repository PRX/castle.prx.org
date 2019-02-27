defmodule Mix.Tasks.Castle.DumpHourly do
  import Ecto.Query
  use Mix.Task

  @shortdoc "Dump the hourly download data into a text file"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [output_dir: :string],
      aliases: [p: :output_dir]

    dump(opts)
  end

  def dump([]) do
    IO.puts "\nUsage:"
    IO.puts "need a `--output_dir` arg\n\n"
  end

  def dump([path: output_dir]) do
    dump_hourly_downloads(output_dir)
  end

  def hourly_downloads_query do
    from h in Castle.HourlyDownload,
    join: e in Castle.Episode,
    on: e.id == h.episode_id,
    order_by: [asc: e.podcast_id],
    select: {h.dtim, h.count, h.episode_id, h.podcast_id, fragment("?::date - ?::date as drop_day_offset", h.dtim, e.published_at)}
  end

  def dump_hourly_downloads(path) do
    Castle.Repo.transaction(fn ->

      hourly_downloads_query
      |> Castle.Repo.stream(timeout: :infinity)
      |> Stream.map(fn row ->

        #m = Map.from_struct(row)
        {dtim, count, episode_id, podcast_id, drop_day_offset} = row
        "#{episode_id} #{podcast_id} #{DateTime.to_iso8601(dtim)} #{count} #{drop_day_offset}\n"
      end)
      |> Stream.into(File.stream!(path)) |> Stream.run
    end, timeout: :infinity)
  end


end
