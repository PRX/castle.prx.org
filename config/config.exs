# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :porter, Porter.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "+DVZXtoG6yRaQrhCNCPNjdyhioRgRlrKMUDDlZkPLXCghP4NCJ+JafxydZD/QnOq",
  render_errors: [view: Porter.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Porter.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Environment config (precompiled OR from env variables)
# MUST release with RELX_REPLACE_OS_VARS=true
config :porter, :env_config,
  bq_client_email: System.get_env("BQ_CLIENT_EMAIL") || "${BQ_CLIENT_EMAIL}",
  bq_private_key: System.get_env("BQ_PRIVATE_KEY") || "${BQ_PRIVATE_KEY}",
  bq_project_id: System.get_env("BQ_PROJECT_ID") || "${BQ_PROJECT_ID}",
  bq_dataset: System.get_env("BQ_DATASET") || "${BQ_DATASET}",
  bq_dovetail_table: System.get_env("BQ_DOVETAIL_TABLE") || "${BQ_DOVETAIL_TABLE}"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
