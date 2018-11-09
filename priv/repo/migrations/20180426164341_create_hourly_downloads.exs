defmodule Castle.Repo.Migrations.CreateHourlyDownloads do
  use Ecto.Migration

  def up do
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
        partition_start DATE;
        partition_end DATE;
        partition TEXT;
      BEGIN
        partition_start := DATE_TRUNC('MONTH', NEW.dtim);
        partition_end := partition_start + INTERVAL '1 MONTH';
        partition := 'hourly_downloads_' || to_char(NEW.dtim,'YYYYMM');
        IF NOT EXISTS(SELECT relname FROM pg_class WHERE relname=partition) THEN
          RAISE NOTICE 'A partition has been created %',partition;
          EXECUTE 'CREATE TABLE ' || partition || ' (CHECK (dtim >= DATE ''' || partition_start || ''' AND dtim < DATE ''' || partition_end || '''), CONSTRAINT ' || partition || '_uniq UNIQUE (episode_id, dtim)) INHERITS (hourly_downloads);';
          EXECUTE 'CREATE INDEX ' || partition || '_podcast_id_index ON ' || partition || ' (podcast_id);';
          EXECUTE 'CREATE INDEX ' || partition || '_episode_id_index ON ' || partition || ' (episode_id);';
          EXECUTE 'CREATE INDEX ' || partition || '_dtim_index ON ' || partition || ' (dtim);';
        END IF;
        EXECUTE 'INSERT INTO ' || partition || ' SELECT(hourly_downloads ' || quote_literal(NEW) || ').* ON CONFLICT ON CONSTRAINT ' || partition || '_uniq DO UPDATE SET (podcast_id, count) = (' || NEW.podcast_id || ', ' || NEW.count || ');';
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
