use Mix.Config

alias Mix.Tasks.Feeder, as: Feeder
alias Mix.Tasks.Postgres, as: Postgres
alias Mix.Tasks.Castle.Rollup, as: Rollup
alias Mix.Tasks.Bigquery.Sync, as: BigQuerySync

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :castle, CastleWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Watch static and templates for browser reloading.
config :castle, CastleWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/castle_web/views/.*(ex)$},
      ~r{lib/castle_web/templates/.*(eex)$}
    ]
  ]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# External clients
config :castle, :redis, Castle.Redis.Api

# Uncomment to run jobs in development
config :castle, Castle.Scheduler,
  jobs: [
    # {"* * * * *", {Feeder.Sync,            :run, [["--lock"]]}},
    # {"* * * * *", {BigQuerySync.Podcasts, :run, [["--lock"]]}},
    # {"* * * * *", {BigQuerySync.Episodes, :run, [["--lock"]]}},
    # {"* * * * *", {BigQuerySync.Agentnames, :run, [["--lock"]]}},
    # {"* * * * *", {BigQuerySync.Geonames,  :run, [["--lock"]]}},
    # {"* * * * *", {Postgres.Vacuum,        :run, [["--lock"]]}},
    # {"* * * * *", {Rollup.Hourly,          :run, [["--lock"]]}},
    # {"* * * * *", {Rollup.Monthly,         :run, [["--lock"]]}},
    # {"* * * * *", {Rollup.Geocountries,    :run, [["--lock"]]}},
    # {"* * * * *", {Rollup.Geometros,       :run, [["--lock"]]}},
    # {"* * * * *", {Rollup.Geosubdivs,      :run, [["--lock"]]}},
    # {"* * * * *", {Rollup.Agents,          :run, [["--lock"]]}},
    # {"* * * * *", {Rollup.MonthlyUniques,  :run, [["--lock"]]}},
    # {"* * * * *", {Rollup.WeeklyUniques,   :run, [["--lock"]]}},
    # {"* * * * *", {Rollup.LastWeekUniques, :run, [["--lock"]]}},
    # {"* * * * *", {Rollup.Last28Uniques,   :run, [["--lock"]]}},
  ]
