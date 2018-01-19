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
     deps: deps(),
     docs: docs()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Castle, []},
     applications: apps(Mix.env)]
  end
  defp apps(:dev), do: [:dotenv | apps()]
  defp apps(:test), do: [:dotenv | apps()]
  defp apps(_), do: apps()
  defp apps, do: [
    :phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
    :jose, :httpoison, :timex, :corsica, :prx_auth
  ]

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2.1"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_html, "~> 2.6"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:ex_doc, "~> 0.14", only: :dev, runtime: false},
     {:gettext, "~> 0.11"},
     {:cowboy, "~> 1.0"},
     {:jose, "~> 1.8"},
     {:httpoison, "~> 0.11"},
     {:uuid, "~> 1.1"},
     {:timex, "~> 3.0"},
     {:redix, ">= 0.6.0"},
     {:corsica, "~> 0.5"},
     {:prx_auth, "~> 0.0.1"},
     {:dotenv, "~> 2.1", only: [:dev, :test]},
     {:mock, "~> 0.2.0", only: :test}]
  end

  defp docs do
    [main: "readme",
     extras: ["README.md"]]
  end
end
