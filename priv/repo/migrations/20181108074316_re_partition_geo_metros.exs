Code.require_file "20180523195208_create_daily_geo_metros.exs", Path.dirname(__ENV__.file)

defmodule Castle.Repo.Migrations.RePartitionGeoMetros do
  use Ecto.Migration

  alias Castle.Repo.Migrations.CreateDailyGeoMetros

  def up do
    CreateDailyGeoMetros.down()
    execute "DELETE FROM rollup_logs WHERE table_name = 'daily_geo_metros'"
    execute """
      CREATE TABLE daily_geo_metros (
        podcast_id integer NOT NULL,
        episode_id uuid NOT NULL,
        metro_code integer NOT NULL,
        day date NOT NULL,
        count integer NOT NULL,
        PRIMARY KEY (episode_id, metro_code, day)
      ) PARTITION BY RANGE (day);
    """
    create index(:daily_geo_metros, [:podcast_id, :metro_code, :day])
  end

  def down do
    drop table(:daily_geo_metros)
    execute "DELETE FROM rollup_logs WHERE table_name = 'daily_geo_metros'"
    CreateDailyGeoMetros.up()
  end
end
