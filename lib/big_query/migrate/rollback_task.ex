defmodule Mix.Tasks.Bigquery.Rollback do
  use BigQuery.Migrate.Utils

  @shortdoc "Rollback bigquery schema migrations"

  def run(_args) do
    start_dependencies()

    # fetch local/remote migrations
    local_migrations = get_migration_files()
    remote_migrations = get_remote_migrations()

    version = remote_migrations |> Enum.sort() |> List.last()
    file = local_migrations[version]

    # handle non-existences
    case {version, file} do
      {nil, _} ->
        IO.puts("nothing to rollback")

      {_, nil} ->
        raise "schema migration #{version} not found locally!"

      {_, _} ->
        module = eval_migration(file)
        IO.puts("running rollback #{version} #{module}...")
        remove_migration(version, do: module.down())
        IO.puts("done")
    end
  end
end
