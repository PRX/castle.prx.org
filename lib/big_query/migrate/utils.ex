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

  def by_month(table) do
    sql = """
      SELECT MIN(partition_id) AS id FROM INFORMATION_SCHEMA.PARTITIONS WHERE table_name = @table
    """

    {[%{id: id}], _meta} = Query.run(sql, table: table)
    str = "#{String.slice(id, 0..3)}-#{String.slice(id, 4..5)}-#{String.slice(id, 6..7)}"

    {:ok, date} = Date.from_iso8601(str)
    month_ranges(date)
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

  def confirm(verb, migrations) do
    dataset = "#{Env.get(:bq_project_id)}.#{Env.get(:bq_dataset)}"
    files = Enum.join(migrations, ", ")
    IO.puts("  you are about #{verb} your #{dataset} dataset with: #{files}")

    warn1 = color(:light_red, "  are you sure about that?", " (yes/no) ")
    warn2 = color(:light_red, "  are you entirely in your right mind?", " (irrelevant/no) ")
    warn3 = color(:red, "  are you inescapably sure about that?", " (you know it/no) ")

    unless String.trim(IO.gets(warn1)) == "yes", do: abort()
    unless String.trim(IO.gets(warn2)) == "irrelevant", do: abort()
    unless String.trim(IO.gets(warn3)) == "you know it", do: abort()
  end

  defp color(color, text, plain_text), do: "#{IO.ANSI.format([color, text])}" <> plain_text
  defp abort(), do: IO.puts("  aborted") && exit(:shutdown)

  defp month_ranges(date) do
    if Date.compare(date, Date.utc_today()) == :gt do
      []
    else
      next_month = Date.end_of_month(date) |> Date.add(1)
      [{date, next_month}] ++ month_ranges(next_month)
    end
  end
end
