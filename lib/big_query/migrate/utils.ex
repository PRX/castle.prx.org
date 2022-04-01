defmodule BigQuery.Migrate.Utils do
  alias BigQuery.Base.Query

  defmacro __using__(_opts) do
    quote do
      use Mix.Task
      import BigQuery.Migrate.Utils
    end
  end

  def start_dependencies do
    {:ok, _started} = Application.ensure_all_started(:memoize)
    {:ok, _started} = Application.ensure_all_started(:new_relic_agent)
    {:ok, _started} = Application.ensure_all_started(:httpoison)
  end

  def create_migrations_table do
    Query.run("CREATE TABLE schema_migrations (version STRING NOT NULL)")
  end

  def get_remote_migrations do
    {results, _meta} = Query.run("SELECT * FROM schema_migrations")
    Enum.map(results, & &1[:version])
  end

  def get_migration_files do
    {:ok, files} = migrations_path() |> File.ls()

    files
    |> Enum.sort()
    |> Enum.map(&{hd(String.split(&1, "_")), &1})
    |> Enum.into(%{})
  end

  def eval_migration(file) do
    {result, _} = Code.eval_file(file, migrations_path())
    Tuple.to_list(result) |> Enum.at(1)
  end

  defmacro add_migration(version, do: block) do
    quote do
      sql = """
        INSERT INTO schema_migrations (version)
        SELECT value FROM (SELECT @version AS value)
        LEFT JOIN schema_migrations ON version = value
        WHERE version IS NULL
      """

      version = unquote(version)
      {_, stats} = Query.run(sql, version: version)

      if stats.changed > 0 do
        try do
          unquote(block)
        rescue
          err ->
            IO.puts("  migration #{version} failed - removing row")
            remove_migration(version)
            raise err
        end
      else
        raise "migration #{version} already running!"
      end
    end
  end

  def add_migration(version), do: add_migration(version, do: nil)

  defmacro remove_migration(version, do: block) do
    quote do
      sql = "DELETE FROM schema_migrations WHERE version = @version"
      version = unquote(version)
      {_, stats} = Query.run(sql, version: version)

      if stats.changed > 0 do
        try do
          unquote(block)
        rescue
          err ->
            IO.puts("  rollback #{version} failed - adding row")
            add_migration(version)
            raise err
        end
      else
        IO.puts("  migration #{version} not found")
      end
    end
  end

  def remove_migration(version), do: remove_migration(version, do: nil)

  def migrations_path, do: "#{:code.priv_dir(:castle)}/big_query/migrations"
end
