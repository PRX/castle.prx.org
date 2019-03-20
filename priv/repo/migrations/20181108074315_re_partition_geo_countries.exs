Code.require_file "20180523195202_create_daily_geo_countries.exs", Path.dirname(__ENV__.file)

defmodule Castle.Repo.Migrations.RePartitionGeoCountries do
  use Ecto.Migration

  alias Castle.Repo.Migrations.CreateDailyGeoCountries

  def up do
    CreateDailyGeoCountries.down()
    execute "DELETE FROM rollup_logs WHERE table_name = 'daily_geo_countries'"
    execute """
      CREATE TABLE daily_geo_countries (
        podcast_id integer NOT NULL,
        episode_id uuid NOT NULL,
        country_iso_code char(3) NOT NULL,
        day date NOT NULL,
        count integer NOT NULL,
        PRIMARY KEY (episode_id, country_iso_code, day)
      ) PARTITION BY RANGE (day);
    """
    create index(:daily_geo_countries, [:podcast_id, :country_iso_code, :day])
  end

  def down do
    drop table(:daily_geo_countries)
    execute "DELETE FROM rollup_logs WHERE table_name = 'daily_geo_countries'"
    CreateDailyGeoCountries.up()
  end
end
