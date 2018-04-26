defmodule Castle.Repo.Migrations.CreateEpisodes do
  use Ecto.Migration

  def change do
    create table(:episodes, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :podcast_id, :integer, null: false
      add :title, :string
      add :subtitle, :text
      add :image_url, :string
      add :created_at, :utc_datetime
      add :updated_at, :utc_datetime
      add :published_at, :utc_datetime
    end
  end
end
