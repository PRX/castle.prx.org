defmodule Castle.Repo.Migrations.CreateWeeklyUniquesTable do
  use Ecto.Migration

  def up do
    execute "DELETE FROM rollup_logs WHERE table_name = 'weekly_uniques'"
    execute """
      CREATE TABLE weekly_uniques (
        podcast_id integer NOT NULL,
        week date NOT NULL,
        count integer NOT NULL,
        PRIMARY KEY (podcast_id, week)
    );
    """
  end

  def down do
    drop table(:weekly_uniques)
    execute "DELETE FROM rollup_logs WHERE table_name = 'weekly_uniques'"
  end
end
