defmodule Castle.Repo.Migrations.CreateLast28UniquesTable do
  use Ecto.Migration

  def up do
    execute "DELETE FROM rollup_logs WHERE table_name = 'last_28_uniques'"
    execute """
      CREATE TABLE last_28_uniques (
        podcast_id integer NOT NULL,
        last_28 date NOT NULL,
        count integer NOT NULL,
        PRIMARY KEY (podcast_id, last_28)
    );
    """
  end

  def down do
    drop table(:last_28_uniques)
    execute "DELETE FROM rollup_logs WHERE table_name = 'last_28_uniques'"
  end
end
