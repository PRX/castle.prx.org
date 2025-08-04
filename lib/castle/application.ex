defmodule Castle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @default_redis_timeout 500
  @default_redis_request_timeout 500

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
    opts =
      [
        host: Env.get(:redis_host),
        port: Env.get(:redis_port),
        ssl: truthy?(Env.get(:redis_ssl)),
        namespace: Env.get(:redis_namespace),
        pool_size: Env.get(:redis_pool_size),
        timeout: Env.get(:redis_timeout) || @default_redis_timeout,
        request_opts: [timeout: Env.get(:redis_request_timeout) || @default_redis_request_timeout],
        socket_opts: redix_ssl_socket_opts(truthy?(Env.get(:redis_ssl))),
        clone: redix_clone_opts()
      ]
      |> reject_blank()

    {RedixClustered, opts}
  end

  defp redix_clone_opts do
    if Env.get(:redis_clone_host) do
      [
        host: Env.get(:redis_clone_host),
        port: Env.get(:redis_clone_port),
        ssl: truthy?(Env.get(:redis_clone_ssl)),
        namespace: Env.get(:redis_clone_namespace),
        pool_size: Env.get(:redis_clone_pool_size),
        timeout: Env.get(:redis_timeout) || @default_redis_timeout,
        request_opts: [timeout: Env.get(:redis_request_timeout) || @default_redis_request_timeout],
        socket_opts: redix_ssl_socket_opts(truthy?(Env.get(:redis_clone_ssl)))
      ]
      |> reject_blank()
    else
      nil
    end
  end

  defp reject_blank(opts) do
    Enum.reject(opts, fn {_key, val} -> is_nil(val) || val == "" || val == [] end)
  end

  defp truthy?(val), do: Enum.member?(["TRUE", "true", true, "1", 1], val)

  # required for elasticache: https://hexdocs.pm/redix/Redix.html#module-ssl
  defp redix_ssl_socket_opts(true) do
    [customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)]]
  end

  defp redix_ssl_socket_opts(_), do: []
end
