defmodule Castle.Repo.Migrations.CreateMonthlyUniquesTable do
  use Ecto.Migration

  def up do
    execute "DELETE FROM rollup_logs WHERE table_name = 'monthly_uniques'"
    create table(:monthly_uniques, primary_key: false) do
        add :podcast_id, :integer, null: false
        add :month, :date,         null: false
        add :count, :integer,      null: false
    end
    create unique_index(:monthly_uniques, [:podcast_id, :month])

  end

  def down do
    drop table(:monthly_uniques)
    execute "DELETE FROM rollup_logs WHERE table_name = 'monthly_uniques'"
  end
end
