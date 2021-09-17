# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :castle, ecto_repos: [Castle.Repo]
config :castle, Castle.Repo, adapter: Ecto.Adapters.Postgres, timeout: 30_000

# Configures the endpoint
config :castle, CastleWeb.Endpoint,
  instrumenters: [NewRelic.Phoenix.Instrumenter],
  url: [host: "localhost"],
  secret_key_base: "+DVZXtoG6yRaQrhCNCPNjdyhioRgRlrKMUDDlZkPLXCghP4NCJ+JafxydZD/QnOq",
  render_errors: [view: CastleWeb.ErrorView, accepts: ~w(html json hal)],
  pubsub_server: MyApp.PubSub,
  http: [compress: true]

# Environment config (precompiled OR from env variables)
# MUST release with RELX_REPLACE_OS_VARS=true
config :castle, :env_config,
  bq_client_email: System.get_env("BQ_CLIENT_EMAIL") || "${BQ_CLIENT_EMAIL}",
  bq_private_key: System.get_env("BQ_PRIVATE_KEY") || "${BQ_PRIVATE_KEY}",
  bq_project_id: System.get_env("BQ_PROJECT_ID") || "${BQ_PROJECT_ID}",
  bq_dataset: System.get_env("BQ_DATASET") || "${BQ_DATASET}",
  client_id: System.get_env("CLIENT_ID") || "${CLIENT_ID}",
  client_secret: System.get_env("CLIENT_SECRET") || "${CLIENT_SECRET}",
  feeder_host: System.get_env("FEEDER_HOST") || "${FEEDER_HOST}",
  id_host: System.get_env("ID_HOST") || "${ID_HOST}",
  new_relic_key: System.get_env("NEW_RELIC_KEY") || "${NEW_RELIC_KEY}",
  new_relic_name: System.get_env("NEW_RELIC_NAME") || "${NEW_RELIC_NAME}",
  redis_host: System.get_env("REDIS_HOST") || "${REDIS_HOST}",
  redis_port: System.get_env("REDIS_PORT") || "${REDIS_PORT}",
  redis_pool_size: System.get_env("REDIS_POOL_SIZE") || "${REDIS_POOL_SIZE}",
  dev_auth: System.get_env("DEV_AUTH") || "${DEV_AUTH}"

# HAL mime type
config :mime, :types, %{
  "application/hal+json" => ["hal"]
}

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Poison

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
