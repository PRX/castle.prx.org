defmodule Castle.Repo.Migrations.AddRollupLogsComplete do
  use Ecto.Migration

  def up do
    alter table(:rollup_logs) do
      add :complete, :boolean, default: false
    end
    execute "UPDATE rollup_logs SET complete = true"
  end

  def down do
    alter table(:rollup_logs) do
      remove :complete
    end
  end
end
