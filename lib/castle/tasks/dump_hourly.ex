defmodule Mix.Tasks.Castle.DumpHourly do
  import Ecto.Query
  use Mix.Task

  @shortdoc "Dump the hourly download data into a text file"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [path: :string],
      aliases: [p: :path]

    dump(opts)
  end

  def dump([]) do
    IO.puts "\nUsage:"
    IO.puts "need a `--path` arg\n\n"
  end
  def dump([path: path]) when is_binary(path) do
    Castle.Repo.transaction(fn ->
      query = from h in Castle.HourlyDownload,
      order_by: [asc: fragment("podcast_id")]

      query
      |> Castle.Repo.stream(timeout: :infinity)
      |> Stream.map(fn row ->
        Map.from_struct(row)
        |> Map.delete(:__meta__)
        |> Jason.encode!
      end)
      |> Stream.into(File.stream!(path)) |> Stream.run
    end, timeout: :infinity)

  end


end
