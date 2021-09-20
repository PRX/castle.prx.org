defmodule Castle.Mixfile do
  use Mix.Project

  def project do
    [
      app: :castle,
      version: "0.0.2",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Castle.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.7"},
      {:postgrex, "~> 0.15"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:gettext, "~> 0.18"},
      {:plug_cowboy, "~> 2.5"},
      {:plug, "~> 1.12"},
      {:jose, "~> 1.11"},
      {:jason, "~> 1.2"},
      {:httpoison, "~> 1.8", override: true},
      {:uuid, "~> 1.1"},
      {:timex, "~> 3.7"},
      {:redix, "~> 1.1"},
      {:corsica, "~> 1.1"},
      {:prx_auth, "~> 0.3.0"},
      {:prx_access, "~> 0.2.0"},
      {:memoize, "~> 1.4"},
      {:quantum, "~> 3.4"},
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false},
      {:mock, "~> 0.3.7", only: :test}
    ]
  end

  defp docs do
    [main: "readme", extras: ["README.md"]]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
