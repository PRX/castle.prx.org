defmodule Castle.Repo.Migrations.AddTotalDownloads do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add :total_downloads, :integer, default: 0
    end
    alter table(:episodes) do
      add :total_downloads, :integer, default: 0
    end
  end
end
