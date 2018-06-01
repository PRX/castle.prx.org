defmodule Castle.Repo.Migrations.AddRollupLogsComplete do
  use Ecto.Migration

  def change do
    alter table(:rollup_logs) do
      add :complete, :boolean, default: false
    end
    execute "UPDATE rollup_logs SET complete = true"
  end
end
