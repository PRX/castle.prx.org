defmodule Castle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      CastleWeb.Telemetry,
      {Phoenix.PubSub, name: Castle.PubSub},
      Castle.Repo,
      CastleWeb.Endpoint,
      Castle.Scheduler,
      redix_clustered_spec()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Castle.Supervisor]

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CastleWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def redix_clustered_spec do
    clone_opts =
      [
        host: Env.get(:redis_clone_host),
        port: Env.get(:redis_clone_port),
        namespace: Env.get(:redis_clone_namespace),
        pool_size: Env.get(:redis_clone_pool_size)
      ]
      |> reject_blank()

    opts =
      [
        host: Env.get(:redis_host),
        port: Env.get(:redis_port),
        namespace: Env.get(:redis_namespace),
        pool_size: Env.get(:redis_pool_size),
        clone: clone_opts
      ]
      |> reject_blank()

    {RedixClustered, opts}
  end

  defp reject_blank(opts) do
    Enum.reject(opts, fn {_key, val} -> is_nil(val) || val == "" || val == [] end)
  end
end
