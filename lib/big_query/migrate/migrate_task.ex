defmodule Mix.Tasks.Bigquery.Migrate do
  use BigQuery.Migrate.Utils

  @shortdoc "Run bigquery schema migrations"

  def run(args) do
    start_dependencies()

    {opts, _, _} =
      OptionParser.parse(args,
        switches: [init: :boolean, all: :boolean],
        aliases: [i: :init, a: :all]
      )

    # optionally create the schema migrations table
    if opts[:init], do: create_migrations_table()

    # fetch local/remote migrations
    local_migrations = get_migration_files()
    remote_migrations = get_remote_migrations()
    pending_migrations = Enum.sort(Map.keys(local_migrations) -- remote_migrations)

    # by default, just run 1 migration
    to_run = if opts[:all], do: pending_migrations, else: Enum.take(pending_migrations, 1)

    if Enum.empty?(to_run) do
      IO.puts("nothing to migrate")
    else
      confirm("migrate", to_run)

      for version <- to_run do
        file = local_migrations[version]
        module = eval_migration(file)

        IO.puts("running migration #{version} #{module}...")
        add_migration(version, do: module.up())
      end

      IO.puts("done")
    end
  end
end
