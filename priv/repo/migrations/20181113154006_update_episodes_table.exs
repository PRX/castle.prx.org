defmodule Castle.Repo.Migrations.UpdateEpisodesTable do
  use Ecto.Migration

  def up do
    execute("""
      CREATE INDEX index_episodes_on_title_idx
      ON episodes
      USING gin(to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(subtitle, '')  ));
      """)

  end
  def down do
    execute("DROP INDEX IF EXISTS index_episodes_on_title_idx;")
  end
end
