defmodule Mix.Tasks.Castle.DumpData do
  import Ecto.Query
  use Mix.Task

  @shortdoc "Dump the hourly download and other data into text files"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} =
      OptionParser.parse(args,
        switches: [output_dir: :string],
        aliases: [d: :output_dir]
      )

    dump(opts)
  end

  def print_help() do
    IO.puts("\nUsage:")
    IO.puts("need a `--output-dir` arg\n\n")
  end

  def dump(output_dir: dir) do
    IO.puts('dumping episode data')
    dump_episodes(dir)
    IO.puts('dumping hourly_download data')
    dump_hourly_downloads(dir)
  end

  def dump(_) do
    print_help()
  end

  def episodes_query do
    from(e in Castle.Episode)
  end

  def hourly_downloads_query do
    from(h in Castle.HourlyDownload,
      join: e in Castle.Episode,
      on: e.id == h.episode_id,
      order_by: [asc: e.podcast_id],
      select:
        {h.dtim, h.count, h.episode_id, h.podcast_id,
         fragment("extract(day from ? - ?)::integer as drop_day", h.dtim, e.published_at)}
    )
  end

  def dump_stream(query, path, row_fun) do
    Castle.Repo.transaction(
      fn ->
        query
        |> Castle.Repo.stream(timeout: :infinity)
        |> Stream.map(row_fun)
        |> Stream.into(File.stream!(path))
        |> Stream.run()
      end,
      timeout: :infinity
    )
  end

  def dump_episodes(dir) do
    episodes_query()
    |> dump_stream(Path.join(dir, 'episodes'), fn e ->
      "#{e.id} #{e.podcast_id} #{DateTime.to_iso8601(e.created_at)} #{DateTime.to_iso8601(e.published_at)}\n"
    end)
  end

  def dump_hourly_downloads(dir) do
    hourly_downloads_query()
    |> dump_stream(Path.join(dir, 'hourly_downloads'), fn row ->
      {dtim, count, episode_id, podcast_id, drop_day} = row
      "#{episode_id} #{podcast_id} #{DateTime.to_iso8601(dtim)} #{count} #{drop_day}\n"
    end)
  end
end
