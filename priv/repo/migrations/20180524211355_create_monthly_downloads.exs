defmodule Castle.Repo.Migrations.CreateMonthlyDownloads do
  use Ecto.Migration

  def change do
    create table(:monthly_downloads, primary_key: false) do
      add :podcast_id, :integer, null: false
      add :episode_id, :uuid, null: false
      add :month, :date, null: false
      add :count, :integer, null: false
    end
    create unique_index(:monthly_downloads, [:episode_id, :month])
    create constraint(:monthly_downloads, :monthly_downloads_date, check: "EXTRACT(DAY from month) = 1")
  end
end
