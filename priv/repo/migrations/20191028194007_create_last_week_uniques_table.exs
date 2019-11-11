defmodule Castle.Repo.Migrations.CreateLastWeekUniquesTable do
  use Ecto.Migration

  def up do
    execute "DELETE FROM rollup_logs WHERE table_name = 'last_week_uniques'"
    create table(:last_week_uniques, primary_key: false) do
        add :podcast_id, :integer, null: false
        add :last_week, :date,     null: false
        add :count, :integer,      null: false
    end
    create unique_index(:last_week_uniques, [:podcast_id, :last_week])
  end

  def down do
    drop table(:last_week_uniques)
    execute "DELETE FROM rollup_logs WHERE table_name = 'last_week_uniques'"
  end
end
