defmodule Castle.Repo.Migrations.CreateLast28UniquesTable do
  use Ecto.Migration

  def up do
    execute "DELETE FROM rollup_logs WHERE table_name = 'last_28_uniques'"
    create table(:last_28_uniques, primary_key: false) do
        add :podcast_id, :integer, null: false
        add :last_28, :date,       null: false
        add :count, :integer,      null: false
    end
    create unique_index(:last_28_uniques, [:podcast_id, :last_28])
  end

  def down do
    drop table(:last_28_uniques)
    execute "DELETE FROM rollup_logs WHERE table_name = 'last_28_uniques'"
  end
end
