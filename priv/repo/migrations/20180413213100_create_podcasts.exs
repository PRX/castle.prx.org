defmodule Castle.Repo.Migrations.CreatePodcasts do
  use Ecto.Migration

  def change do
    create table(:podcasts) do
      add :podcast_id, :integer
      add :account_id, :integer
      add :name, :string
      add :created_at, :utc_datetime
      add :updated_at, :utc_datetime
      add :published_at, :utc_datetime
    end
  end
end
