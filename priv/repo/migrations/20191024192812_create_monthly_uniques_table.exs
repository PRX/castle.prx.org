defmodule Castle.Repo.Migrations.CreateMonthlyUniquesTable do
  use Ecto.Migration

  def up do
    execute "DELETE FROM rollup_logs WHERE table_name = 'monthly_uniques'"
    execute """
      CREATE TABLE monthly_uniques (
        podcast_id integer NOT NULL,
        month date NOT NULL,
        count integer NOT NULL,
        PRIMARY KEY (podcast_id, month)
    );
    """
  end

  def down do
    drop table(:monthly_uniques)
    execute "DELETE FROM rollup_logs WHERE table_name = 'monthly_uniques'"
  end
end
