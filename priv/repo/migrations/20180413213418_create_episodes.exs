defmodule Castle.Repo.Migrations.CreateEpisodes do
  use Ecto.Migration

  def change do
    create table(:episodes, primary_key: false) do
      add :guid, :string, primary_key: true
      add :podcast_id, :integer, null: false
      add :name, :string
      add :created_at, :utc_datetime
      add :updated_at, :utc_datetime
      add :published_at, :utc_datetime
    end
  end
end
