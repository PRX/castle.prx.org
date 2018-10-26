defmodule Castle.Redis.Pool do
  @default_pool_size 5

  def child_spec(_args) do
    children =
      for i <- 0..(pool_size() - 1) do
        Supervisor.child_spec({Redix, config(i)}, id: {Redix, i})
      end

    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  def config(num) do
    [
      host: Env.get(:redis_host),
      port: Env.get(:redis_port),
      database: Application.get_env(:castle, :redis_database),
      name: :"redix_#{num}",
    ] |> Enum.filter(fn({_key, val}) -> val end)
  end

  def command(command) do
    Redix.command(:"redix_#{random_index()}", command)
  end

  def pipeline(commands) do
    Redix.pipeline(:"redix_#{random_index()}", commands)
  end

  defp random_index() do
    rem(System.unique_integer([:positive]), pool_size())
  end

  defp pool_size do
    Env.get(:redis_pool_size) || @default_pool_size
  end
end
