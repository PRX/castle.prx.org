defmodule Castle.Repo.Migrations.AddEpisodeFeedSlugs do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      add(:feed_slugs, {:array, :text})
    end
  end
end
