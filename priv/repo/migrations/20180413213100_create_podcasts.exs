defmodule Castle.Repo.Migrations.CreatePodcasts do
  use Ecto.Migration

  def change do
    create table(:podcasts, primary_key: false) do
      add :id, :integer, primary_key: true
      add :account_id, :integer
      add :title, :string
      add :subtitle, :text
      add :image_url, :string
      add :created_at, :utc_datetime
      add :updated_at, :utc_datetime
      add :published_at, :utc_datetime
    end
  end
end
