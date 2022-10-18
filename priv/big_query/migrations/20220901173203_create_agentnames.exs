defmodule BigQuery.Migrations.CreateAgentnames do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      CREATE TABLE agentnames
      (
        agentname_id INT64 NOT NULL,
        tag STRING
      )
      OPTIONS(description="PRX podagents");
    """)
  end

  def down do
    Query.log("""
      DROP TABLE agentnames;
    """)
  end
end
