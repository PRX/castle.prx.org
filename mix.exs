defmodule Castle.Mixfile do
  use Mix.Project

  def project do
    [
      app: :castle,
      version: "0.0.2",
      elixir: "~> 1.7",
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
      extra_applications: extras(Mix.env())
    ]
  end

  defp extras(:dev), do: [:dotenv | extras()]
  defp extras(:test), do: [:dotenv | extras()]
  defp extras(_), do: extras()
  defp extras, do: [:logger, :runtime_tools]

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.2"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"},
      {:plug, "~> 1.7"},
      {:jose, "~> 1.8"},
      {:httpoison, "~> 1.0", override: true},
      {:uuid, "~> 1.1"},
      {:timex, "~> 3.0"},
      {:redix, ">= 0.6.0"},
      {:corsica, "~> 1.0"},
      {:prx_auth, "~> 0.1.0"},
      {:prx_access, "~> 0.2.0"},
      {:memoize, "~> 1.2"},
      {:quantum, "~> 2.2"},
      {:new_relic_phoenix, "~> 0.1"},
      {:dotenv, "~> 3.0", only: [:dev, :test]},
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
      {:mock, "~> 0.3.1", only: :test}
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
