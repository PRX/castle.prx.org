defmodule Castle.Repo.Migrations.RenameEpisodeKeywords do
  use Ecto.Migration

  def change do
    rename(table(:episodes), :keywords, to: :categories)
  end
end
