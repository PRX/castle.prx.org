defmodule Castle.Repo.Migrations.CreateHourlyDownloads do
  use Ecto.Migration

  def change do
    create table(:hourly_downloads, primary_key: false) do
      add :podcast_id, :integer, null: false
      add :episode_id, :uuid, null: false
      add :dtim, :utc_datetime, null: false
      add :count, :integer, null: false
    end

    execute """
    CREATE OR REPLACE FUNCTION create_hourly_downloads_partition() RETURNS trigger AS
    $$
      DECLARE
        partition_month TEXT;
        partition TEXT;
      BEGIN
        partition_month := to_char(NEW.dtim,'YYYYMM');
        partition := 'hourly_downloads_' || partition_month;
        IF NOT EXISTS(SELECT relname FROM pg_class WHERE relname=partition) THEN
          RAISE NOTICE 'A partition has been created %',partition;
          EXECUTE 'CREATE TABLE ' || partition ||
            ' (CHECK (TO_CHAR(dtim,''YYYYMM'') = ''' || partition_month || '''))' ||
            ' INHERITS (hourly_downloads);';
          EXECUTE 'CREATE INDEX ' || partition || '_podcast_id_index ON ' || partition || ' (podcast_id);';
          EXECUTE 'CREATE INDEX ' || partition || '_episode_id_index ON ' || partition || ' (episode_id);';
          EXECUTE 'CREATE UNIQUE INDEX ' || partition || '_episode_id_dtim_index ON ' || partition || ' (episode_id, dtim);';
        END IF;
        EXECUTE 'INSERT INTO ' || partition || ' SELECT(hourly_downloads ' || quote_literal(NEW) || ').*;';
        RETURN NULL;
      END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER hourly_downloads_partition_insert_trigger
    BEFORE INSERT ON hourly_downloads
    FOR EACH ROW EXECUTE PROCEDURE create_hourly_downloads_partition();
    """
  end

  def down do
    Enum.map inherited_tables(), fn(table_name) ->
      drop table(table_name)
    end
    drop table(:hourly_downloads)
    execute "DROP FUNCTION create_hourly_downloads_partition()"
  end

  defp inherited_tables do
    query = "select tablename from pg_tables where tablename like 'hourly_downloads\_______'"
    result = Ecto.Adapters.SQL.query!(Castle.Repo, query, [])
    List.flatten(result.rows)
  end
end
