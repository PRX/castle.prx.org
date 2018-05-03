use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :castle, CastleWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :castle, Castle.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

# External clients
config :castle, :redis, Castle.FakeRedis
config :castle, :bigquery, BigQuery

# Run against a different redis database, so we're not messing with dev data
config :castle, :redis_database, 2
