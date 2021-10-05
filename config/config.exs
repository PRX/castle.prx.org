use Mix.Config

# General application configuration
config :castle, ecto_repos: [Castle.Repo]
config :castle, Castle.Repo, adapter: Ecto.Adapters.Postgres, timeout: 30_000, log: false

# Configures the endpoint
config :castle, CastleWeb.Endpoint,
  render_errors: [view: CastleWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Castle.PubSub,
  http: [compress: true]

# Configures Elixir's Logger
config :logger, :console,
  format: {Castle.JsonLogger, :format},
  metadata: :all,
  utc_log: true,
  level: :info

# Use Poison for JSON parsing in Phoenix
config :phoenix, :json_library, Poison

# Import runtime ENV configs
import_config "env.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
