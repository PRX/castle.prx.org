defmodule BigQuery.Migrations.AddFeedSlugsToEpisodes do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE episodes ADD COLUMN feed_slugs ARRAY<STRING>;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE episodes DROP COLUMN feed_slugs;
    """)
  end
end
