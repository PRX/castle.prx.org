ExUnit.configure exclude: [:external]
ExUnit.start
Ecto.Adapters.SQL.Sandbox.mode(Castle.Repo, :manual)
