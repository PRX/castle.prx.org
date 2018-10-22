defmodule Castle.Mixfile do
  use Mix.Project

  def project do
    [app: :castle,
     version: "0.0.1",
     elixir: "~> 1.6",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
     docs: docs()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Castle.Application, []},
      applications: apps(Mix.env),
      extra_applications: [:logger, :runtime_tools]
    ]
  end
  defp apps(:dev), do: [:dotenv | apps()]
  defp apps(:test), do: [:dotenv | apps()]
  defp apps(_), do: apps()
  defp apps, do: [
    :phoenix, :phoenix_pubsub, :phoenix_ecto, :postgrex, :phoenix_html,
    :cowboy, :logger, :gettext, :jose, :httpoison, :timex, :corsica, :prx_auth,
    :memoize
  ]

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.4.0-rc", override: true},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.2"},
     {:postgrex, ">= 0.0.0"},
     {:phoenix_html, "~> 2.10"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:ex_doc, "~> 0.14", only: :dev, runtime: false},
     {:gettext, "~> 0.11"},
     {:plug_cowboy, "~> 2.0"},
     {:plug, "~> 1.7"},
     {:jose, "~> 1.8"},
     {:httpoison, "~> 0.13"},
     {:uuid, "~> 1.1"},
     {:timex, "~> 3.0"},
     {:redix, ">= 0.6.0"},
     {:corsica, "~> 0.5"},
     {:prx_auth, "~> 0.0.1"},
     {:memoize, "~> 1.2"},
     {:quantum, "~> 2.2"},
     {:dotenv, "~> 2.1", only: [:dev, :test]},
     {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
     {:mock, "~> 0.3.1", only: :test}]
  end

  defp docs do
    [main: "readme",
     extras: ["README.md"]]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test": ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
