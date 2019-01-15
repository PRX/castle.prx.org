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

  def dump_hourly_downloads(path) do
    Castle.Repo.transaction(fn ->
      query = from h in Castle.HourlyDownload,
      select: {h.dtim, h.count, h.episode_id, h.podcast_id},
      order_by: [asc: fragment("podcast_id")]

      query
      |> Castle.Repo.stream(timeout: :infinity)
      |> Stream.map(fn row ->

        #m = Map.from_struct(row)
        {dtim, count, episode_id, podcast_id} = row
        "#{episode_id} #{podcast_id} #{DateTime.to_iso8601(dtim)} #{count}\n"
      end)
      |> Stream.into(File.stream!(path)) |> Stream.run
    end, timeout: :infinity)
  end


end
