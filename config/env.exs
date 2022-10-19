use Mix.Config

# in some environments, vars get double quoted
defmodule RuntimeEnv do
  def get(name), do: System.get_env(name) |> dequote()
  def dequote("\"" <> rest), do: String.replace(rest, ~r/"$/, "")
  def dequote(val), do: val
end

# boostrap .env for local dev
if (Mix.env() == :dev || Mix.env() == :test) && File.exists?(".env") do
  {:ok, str} = File.read(".env")

  Enum.each(String.split(str, "\n"), fn line ->
    case String.split(line, "=", parts: 2) do
      ["#" <> _key, _val] -> nil
      [_key, ""] -> nil
      [key, val] -> System.put_env(key, String.replace(val, ~r/^"|"$/, ""))
      _any -> nil
    end
  end)
end

# ensure a secret is set in prod
case {Mix.env(), RuntimeEnv.get("SECRET_KEY_BASE")} do
  {:prod, ""} -> raise("You must set a SECRET_KEY_BASE env")
  {:prod, nil} -> raise("You must set a SECRET_KEY_BASE env")
  _ -> true
end

# web endpoint configs
port =
  case RuntimeEnv.get("PORT") do
    "" -> 4000
    "" <> num -> String.to_integer(num)
    _ -> 4000
  end

config :castle, CastleWeb.Endpoint,
  url: [host: "localhost", port: port],
  http: [port: port],
  secret_key_base: RuntimeEnv.get("SECRET_KEY_BASE")

# optional new relic
config :new_relic_agent,
  app_name: RuntimeEnv.get("NEW_RELIC_APP_NAME"),
  license_key: RuntimeEnv.get("NEW_RELIC_LICENSE_KEY")

# env values (the Env module itself will de-quote these)
config :castle, Env,
  bq_client_email: System.get_env("BQ_CLIENT_EMAIL"),
  bq_private_key: System.get_env("BQ_PRIVATE_KEY"),
  bq_project_id: System.get_env("BQ_PROJECT_ID"),
  bq_dataset: System.get_env("BQ_DATASET"),
  client_id: System.get_env("CLIENT_ID"),
  client_secret: System.get_env("CLIENT_SECRET"),
  feeder_host: System.get_env("FEEDER_HOST"),
  id_host: System.get_env("ID_HOST"),
  maxmind_license_key: System.get_env("MAXMIND_LICENSE_KEY"),
  redis_host: System.get_env("REDIS_HOST"),
  redis_port: System.get_env("REDIS_PORT"),
  redis_namespace: System.get_env("REDIS_NAMESPACE"),
  redis_pool_size: System.get_env("REDIS_POOL_SIZE"),
  redis_clone_host: System.get_env("REDIS_CLONE_HOST"),
  redis_clone_port: System.get_env("REDIS_CLONE_PORT"),
  redis_clone_namespace: System.get_env("REDIS_CLONE_NAMESPACE"),
  redis_clone_pool_size: System.get_env("REDIS_CLONE_POOL_SIZE"),
  dev_auth: System.get_env("DEV_AUTH")
