defmodule Castle do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Castle.Endpoint, []),
      worker(Castle.Rollup.Worker, [])
    ]

    # Create the redix children list of workers:
    redix_config =
      [host: Env.get(:redis_host), port: Env.get(:redis_port)]
      |> Enum.filter(fn({_key, val}) -> val end)
    redix_size = 5
    redix_workers = for i <- 0..(redix_size - 1) do
      worker(Redix, [redix_config, [name: :"redix_#{i}"]], id: {Redix, i})
    end
    children = children ++ redix_workers

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Castle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Castle.Endpoint.config_change(changed, removed)
    :ok
  end
end
