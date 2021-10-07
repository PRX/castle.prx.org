defmodule Castle.Redis.Conn do
  @redis Application.get_env(:castle, :redis_library)

  def get(keys) when is_list(keys) do
    Enum.map(keys, &get/1)
  end

  def get(key) do
    command(["GET", key]) |> decode()
  end

  # NOTE: cannot pipeline since keys may be on different cluster nodes
  def hget(keys, field) when is_list(keys) do
    Enum.map(keys, fn key ->
      pipeline([["EXISTS", key], ["HGET", key, field]]) |> decode()
    end)
  end

  def hget(key, field) do
    command(["HGET", key, field]) |> decode()
  end

  def hgetall(key) do
    command(["HGETALL", key])
    |> Enum.chunk_every(2)
    |> Enum.into(%{}, fn [k, v] -> {k, decode(v)} end)
    |> Map.delete("_")
  end

  def ttl(key) do
    command(["TTL", key])
  end

  def set(sets) when is_map(sets) do
    Enum.map(sets, fn {key, val} -> set(key, val) end)
  end

  def set(sets) when is_list(sets) do
    Enum.map(sets, fn {key, ttl, val} -> set(key, ttl, val) end)
  end

  def set(sets, ttl) when is_map(sets) do
    Enum.map(sets, fn {key, val} -> set(key, ttl, val) end)
  end

  def set(key, val) do
    command(["SET", key, encode(val)])
    val
  end

  def set(key, nil, val), do: set(key, val)

  def set(key, ttl, val) do
    command(["SETEX", key, ttl, encode(val)])
    val
  end

  def setnx(key, ttl, val) do
    case command(["SET", key, encode(val), "EX", ttl, "NX"]) do
      nil -> false
      _ok -> true
    end
  end

  def hset(key, field, val) do
    command(["HSET", key, field, encode(val)])
  end

  def hsetall(key, sets), do: hsetall(key, sets, 0)

  def hsetall(key, sets, ttl) when is_map(sets) do
    [
      ["MULTI"],
      ["DEL", key],
      ["HMSET", key, "_", 0] ++ encode_multiple(sets),
      expire_cmd(key, ttl),
      ["EXEC"]
    ]
    |> Enum.filter(&(!is_nil(&1)))
    |> pipeline()
  end

  def del(key) do
    case command(["DEL", key]) do
      num when num > 0 -> true
      _ -> false
    end
  end

  defp encode(nil), do: nil

  defp encode(value) do
    {:ok, encoded} = Poison.encode(value)
    encoded
  end

  defp encode_multiple(values) when is_map(values) do
    values
    |> Enum.map(fn {fld, val} -> {"#{fld}", encode(val)} end)
    |> Enum.map(&Tuple.to_list/1)
    |> List.flatten()
  end

  defp decode(nil), do: nil
  defp decode(0), do: false
  defp decode(1), do: true
  defp decode(values) when is_list(values), do: Enum.map(values, &decode/1)

  defp decode(value) do
    # TODO: probably switch back to string keys, to avoid atom exhaustion
    case Poison.decode(value, keys: :atoms) do
      {:ok, decoded} ->
        decoded

      err ->
        IO.inspect(err)
        nil
    end
  end

  def command(command) do
    case @redis.command(command) do
      {:ok, val} -> val
      _ -> nil
    end
  end

  def pipeline(commands) do
    case @redis.pipeline(commands) do
      {:ok, vals} -> vals
      _ -> Enum.map(commands, fn _ -> nil end)
    end
  end

  defp expire_cmd(_key, 0), do: nil
  defp expire_cmd(_key, nil), do: nil
  defp expire_cmd(key, ttl), do: ["EXPIRE", key, ttl]
end
