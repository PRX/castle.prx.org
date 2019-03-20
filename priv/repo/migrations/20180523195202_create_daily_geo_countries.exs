defmodule Castle.Repo.Migrations.CreateDailyGeoCountries do
  use Ecto.Migration

  def up do
    create table(:daily_geo_countries, primary_key: false) do
      add :podcast_id, :integer, null: false
      add :episode_id, :uuid, null: false
      add :country_iso_code, :string, null: false
      add :day, :date, null: false
      add :count, :integer, null: false
    end

    execute """
    CREATE OR REPLACE FUNCTION create_daily_geo_countries_partition() RETURNS trigger AS
    $$
      DECLARE
        partition_start DATE;
        partition_end DATE;
        partition TEXT;
      BEGIN
        partition_start := DATE_TRUNC('MONTH', NEW.day);
        partition_end := partition_start + INTERVAL '1 MONTH';
        partition := 'daily_geo_countries_' || to_char(NEW.day,'YYYYMM');
        IF NOT EXISTS(SELECT relname FROM pg_class WHERE relname=partition) THEN
          RAISE NOTICE 'A partition has been created %',partition;
          EXECUTE 'CREATE TABLE ' || partition || ' (CHECK (day >= DATE ''' || partition_start || ''' AND day < DATE ''' || partition_end || '''), CONSTRAINT ' || partition || '_uniq UNIQUE (episode_id, country_iso_code, day)) INHERITS (daily_geo_countries);';
          EXECUTE 'CREATE INDEX ' || partition || '_podcast_id_index ON ' || partition || ' (podcast_id);';
          EXECUTE 'CREATE INDEX ' || partition || '_episode_id_index ON ' || partition || ' (episode_id);';
          EXECUTE 'CREATE INDEX ' || partition || '_day_index ON ' || partition || ' (day);';
        END IF;
        EXECUTE 'INSERT INTO ' || partition || ' SELECT(daily_geo_countries ' || quote_literal(NEW) || ').* ON CONFLICT ON CONSTRAINT ' || partition || '_uniq DO UPDATE SET (podcast_id, count) = (' || NEW.podcast_id || ', ' || NEW.count || ');';
        RETURN NULL;
      END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER daily_geo_countries_partition_insert_trigger
    BEFORE INSERT ON daily_geo_countries
    FOR EACH ROW EXECUTE PROCEDURE create_daily_geo_countries_partition();
    """
  end

  def down do
    Enum.map inherited_tables(), fn(table_name) ->
      drop table(table_name)
    end
    drop table(:daily_geo_countries)
    execute "DROP FUNCTION create_daily_geo_countries_partition()"
  end

  defp inherited_tables do
    query = "select tablename from pg_tables where tablename like 'daily_geo_countries\_______'"
    result = Ecto.Adapters.SQL.query!(Castle.Repo, query, [])
    List.flatten(result.rows)
  end
end
