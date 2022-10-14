defmodule BigQuery.Migrations.CreateMetronames do
  alias BigQuery.Base.Query

  def up do
    values =
      Castle.Label.GeoMetro.all()
      |> Enum.map(fn {k, v} -> "(#{k},'#{v}')" end)
      |> Enum.join(",")

    Query.log("""
      CREATE TABLE metronames
      (
        code INT64 NOT NULL,
        label STRING
      )
      OPTIONS(description="Metro code labels");

      INSERT metronames (code, label) VALUES #{values};
    """)
  end

  def down do
    Query.log("DROP TABLE metronames;")
  end
end
