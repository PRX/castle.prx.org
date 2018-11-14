defmodule Castle.Repo.Migrations.AddSearch do
  use Ecto.Migration

  def up do
    execute("""
      CREATE INDEX index_episodes_for_search_idx
      ON episodes
      USING gin(to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(subtitle, '')  ));
      """)

    execute("""
      CREATE INDEX index_podcasts_for_search_idx
      ON episodes
      USING gin(to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(subtitle, '')  ));
      """)
  end
  def down do
    execute("DROP INDEX IF EXISTS index_episodes_for_search_idx;")
    execute("DROP INDEX IF EXISTS index_podcasts_for_search_idx;")
  end
end
