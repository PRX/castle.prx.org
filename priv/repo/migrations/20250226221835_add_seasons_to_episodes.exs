defmodule Castle.Repo.Migrations.AddSeasonsToEpisodes do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      add(:season_number, :integer)
      add(:episode_number, :integer)
    end
  end
end
