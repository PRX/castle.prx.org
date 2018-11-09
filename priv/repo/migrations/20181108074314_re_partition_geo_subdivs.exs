Code.require_file "20180522223601_create_daily_geo_subdivs.exs", Path.dirname(__ENV__.file)

defmodule Castle.Repo.Migrations.RePartitionGeoSubdivs do
  use Ecto.Migration

  alias Castle.Repo.Migrations.CreateDailyGeoSubdivs

  def up do
    CreateDailyGeoSubdivs.down()
    execute "DELETE FROM rollup_logs WHERE table_name = 'daily_geo_subdivs'"
    execute """
      CREATE TABLE daily_geo_subdivs (
        podcast_id integer NOT NULL,
        episode_id uuid NOT NULL,
        country_iso_code char(3) NOT NULL,
        subdivision_1_iso_code char(3) NOT NULL,
        day date NOT NULL,
        count integer NOT NULL,
        PRIMARY KEY (episode_id, country_iso_code, subdivision_1_iso_code, day)
      ) PARTITION BY RANGE (day);
    """
    create index(:daily_geo_subdivs, [:podcast_id, :country_iso_code, :subdivision_1_iso_code, :day])
  end

  def down do
    drop table(:daily_geo_subdivs)
    execute "DELETE FROM rollup_logs WHERE table_name = 'daily_geo_subdivs'"
    CreateDailyGeoSubdivs.up()
  end
end
