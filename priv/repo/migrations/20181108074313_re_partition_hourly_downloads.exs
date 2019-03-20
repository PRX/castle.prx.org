Code.require_file "20180426164341_create_hourly_downloads.exs", Path.dirname(__ENV__.file)

defmodule Castle.Repo.Migrations.RePartitionHourlyDownloads do
  use Ecto.Migration

  alias Castle.Repo.Migrations.CreateHourlyDownloads

  def up do
    CreateHourlyDownloads.down()
    execute "DELETE FROM rollup_logs WHERE table_name = 'hourly_downloads'"
    execute """
      CREATE TABLE hourly_downloads (
        podcast_id integer NOT NULL,
        episode_id uuid NOT NULL,
        dtim timestamp without time zone NOT NULL,
        count integer NOT NULL,
        PRIMARY KEY (episode_id, dtim)
      ) PARTITION BY RANGE (dtim);
    """
    create index(:hourly_downloads, [:podcast_id, :dtim])
  end

  def down do
    drop table(:hourly_downloads)
    execute "DELETE FROM rollup_logs WHERE table_name = 'hourly_downloads'"
    CreateHourlyDownloads.up()
  end
end
