defmodule Castle.Repo.Migrations.CreateRollupLogs do
  use Ecto.Migration

  def change do
    create table(:rollup_logs) do
      add :table_name, :string, null: false
      add :date, :date, null: false
      timestamps()
    end
    create unique_index(:rollup_logs, [:table_name, :date])
  end
end
