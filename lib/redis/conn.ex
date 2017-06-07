defmodule Castle.Redis.Conn do

  def get(keys, opts) when is_list(keys) do
    keys |> Enum.map(&(["GET", &1])) |> pipeline(opts) |> decode()
  end
  def get(key, opts) do
    ["GET", key] |> command(opts) |> decode()
  end

  def set(key, val, opts \\ []) do
    set_cmd(key, Keyword.get(opts, :ttl), val) |> command(opts)
    val
  end

  def setall(sets, opts \\ []) do
    Enum.map(sets, &set_cmd/1) |> pipeline(opts)
    Enum.map(sets, &set_vals/1)
  end

  def del(key, opts \\ []) do
    case command(["DEL", key], opts) do
      num when num > 0 -> true
      _ -> false
    end
  end

  defp encode(nil), do: nil
  defp encode(value) do
    {:ok, encoded} = Poison.encode(value)
    encoded
  end

  defp decode(nil), do: nil
  defp decode(values) when is_list(values), do: Enum.map(values, &decode/1)
  defp decode(value) do
    # TODO: probably switch back to string keys, to avoid atom exhaustion
    case Poison.decode(value, keys: :atoms) do
      {:ok, decoded} -> decoded
      err -> IO.inspect(err); nil
    end
  end

  def command([operation | _args] = command, opts) do
    NewRelixir.Plug.Instrumentation.instrument_db(:redis, operation, opts, fn() ->
      case Redix.command(:"redix_#{random_index()}", command) do
        {:ok, val} -> val
        _ -> nil
      end
    end)
  end

  def pipeline(commands, opts) do
    ops = commands |> Enum.map(&hd/1) |> Enum.uniq |> Enum.join("/")
    NewRelixir.Plug.Instrumentation.instrument_db(:redis, "PIPELINE(#{ops})", opts, fn() ->
      case Redix.pipeline(:"redix_#{random_index()}", commands) do
        {:ok, vals} -> vals
        _ -> Enum.map(commands, fn(_) -> nil end)
      end
    end)
  end

  defp set_cmd(key, nil, val), do: set_cmd(key, val)
  defp set_cmd(key, ttl, val), do: ["SETEX", key, ttl, encode(val)]
  defp set_cmd(key, val), do: ["SET", key, encode(val)]
  defp set_cmd([{key, ttl, val} | rest]), do: set_cmd(key, ttl, val) ++ set_cmd(rest)
  defp set_cmd([{key, val} | rest]), do: set_cmd(key, val) ++ set_cmd(rest)
  defp set_cmd(_), do: []

  defp set_vals([{key, ttl, val} | rest]), do: val ++ set_vals(rest)
  defp set_vals([{key, val} | rest]), do: val ++ set_vals(rest)
  defp set_vals(_), do: []

  defp random_index() do
    rem(System.unique_integer([:positive]), 5)
  end
end
