defmodule Castle.Repo.Migrations.CreateLastWeekUniquesTable do
  use Ecto.Migration


  def up do
    execute "DELETE FROM rollup_logs WHERE table_name = 'last_week_uniques'"
    execute """
      CREATE TABLE last_week_uniques (
        podcast_id integer NOT NULL,
        week date NOT NULL,
        count integer NOT NULL,
        PRIMARY KEY (podcast_id, week)
    );
    """
  end

  def down do
    drop table(:last_week_uniques)
    execute "DELETE FROM rollup_logs WHERE table_name = 'last_week_uniques'"
  end
end
