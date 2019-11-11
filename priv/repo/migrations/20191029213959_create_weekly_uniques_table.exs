defmodule Castle.Repo.Migrations.CreateWeeklyUniquesTable do
  use Ecto.Migration

  def up do
    execute "DELETE FROM rollup_logs WHERE table_name = 'weekly_uniques'"
    create table(:weekly_uniques, primary_key: false) do
        add :podcast_id, :integer, null: false, primary: true
        add :week, :date, null: false, primary: true
        add :count, :integer, null: false
    end
    create unique_index(:weekly_uniques, [:podcast_id, :week])
  end

  def down do
    drop table(:weekly_uniques)
    execute "DELETE FROM rollup_logs WHERE table_name = 'weekly_uniques'"
  end
end
