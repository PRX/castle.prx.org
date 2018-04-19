defmodule Castle.Repo.Migrations.CreateEpisodes do
  use Ecto.Migration

  def change do
    create table(:episodes) do
      add :podcast_id, :integer, primary: true
      add :episode_guid, :string, unique: true
      add :name, :string
      add :created_at, :utc_datetime
      add :updated_at, :utc_datetime
      add :published_at, :utc_datetime
    end
  end
end
