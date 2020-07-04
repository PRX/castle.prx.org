defmodule Castle.Repo.Migrations.EpisodesHaveTags do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      add(:keywords, {:array, :string})
    end
  end
end
