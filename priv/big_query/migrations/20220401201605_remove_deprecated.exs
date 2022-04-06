defmodule BigQuery.Migrations.RemoveDeprecated do
  alias BigQuery.Base.Query

  # all our shows flipped to IAB2 within a few days of this
  @first_is_bytes ~U[2019-05-22 19:00:00.000Z]

  def up do
    Query.log("""
      ALTER TABLE dt_downloads
      DROP COLUMN program,
      DROP COLUMN path,
      DROP COLUMN clienthash,
      DROP COLUMN postal_code,
      DROP COLUMN latitude,
      DROP COLUMN longitude,
      DROP COLUMN is_bytes,
      DROP COLUMN listener_session;

      ALTER TABLE dt_impressions
      DROP COLUMN is_bytes,
      DROP COLUMN listener_session;
    """)
  end

  def down do
    Query.log(
      """
        ALTER TABLE dt_downloads
        ADD COLUMN program STRING,
        ADD COLUMN path STRING,
        ADD COLUMN clienthash STRING,
        ADD COLUMN postal_code STRING,
        ADD COLUMN latitude FLOAT64,
        ADD COLUMN longitude FLOAT64,
        ADD COLUMN is_bytes BOOL,
        ADD COLUMN listener_session STRING;

        UPDATE dt_downloads SET is_bytes = true WHERE timestamp >= @first_is_bytes;

        ALTER TABLE dt_impressions
        ADD COLUMN is_bytes BOOL,
        ADD COLUMN listener_session STRING;
      """,
      first_is_bytes: @first_is_bytes
    )
  end
end
