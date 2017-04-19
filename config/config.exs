# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :castle, Castle.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "+DVZXtoG6yRaQrhCNCPNjdyhioRgRlrKMUDDlZkPLXCghP4NCJ+JafxydZD/QnOq",
  render_errors: [view: Castle.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Castle.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Environment config (precompiled OR from env variables)
# MUST release with RELX_REPLACE_OS_VARS=true
config :castle, :env_config,
  bq_client_email: System.get_env("BQ_CLIENT_EMAIL") || "${BQ_CLIENT_EMAIL}",
  bq_private_key: System.get_env("BQ_PRIVATE_KEY") || "${BQ_PRIVATE_KEY}",
  bq_project_id: System.get_env("BQ_PROJECT_ID") || "${BQ_PROJECT_ID}",
  bq_dataset: System.get_env("BQ_DATASET") || "${BQ_DATASET}",
  bq_downloads_table: System.get_env("BQ_DOWNLOADS_TABLE") || "${BQ_DOWNLOADS_TABLE}",
  bq_impressions_table: System.get_env("BQ_IMPRESSIONS_TABLE") || "${BQ_IMPRESSIONS_TABLE}",
  redis_host: System.get_env("REDIS_HOST") || "${REDIS_HOST}",
  redis_port: System.get_env("REDIS_PORT") || "${REDIS_PORT}",
  redis_pool_size: System.get_env("REDIS_POOL_SIZE") || "${REDIS_POOL_SIZE}",
  basic_auth_user: System.get_env("BASIC_AUTH_USER") || "${BASIC_AUTH_USER}",
  basic_auth_pass: System.get_env("BASIC_AUTH_PASS") || "${BASIC_AUTH_PASS}"

# HAL mime type
config :mime, :types, %{
  "application/hal+json" => ["hal"],
}

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
