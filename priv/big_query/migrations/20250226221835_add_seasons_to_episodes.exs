defmodule BigQuery.Migrations.AddSeasonToEpisodes do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE episodes ADD COLUMN season_number INT64;
    """)
    Query.log("""
      ALTER TABLE episodes ADD COLUMN episode_number INT64;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE episodes DROP COLUMN season_number;
    """)
    Query.log("""
      ALTER TABLE episodes DROP COLUMN episode_number;
    """)
  end
end
