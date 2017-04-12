defmodule Castle.Redis.Conn do

  def get(keys) when is_list(keys) do
    keys |> Enum.map(&(["GET", &1])) |> pipeline() |> decode()
  end
  def get(key) do
    command(["GET", key]) |> decode()
  end

  def set(sets) when is_map(sets) do
    sets |> Enum.map(fn({key, val}) -> ["SET", key, encode(val)] end) |> pipeline()
    sets
  end
  def set(sets, ttl) when is_map(sets) do
    sets |> Enum.map(fn({key, val}) -> ["SETEX", key, ttl, encode(val)] end) |> pipeline()
    sets
  end
  def set(key, val) do
    command ["SET", key, encode(val)]
    val
  end
  def set(key, ttl, val) do
    command ["SETEX", key, ttl, encode(val)]
    val
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

  defp decode(nil), do: nil
  defp decode(values) when is_list(values), do: Enum.map(values, &decode/1)
  defp decode(value) do
    case Poison.decode(value, keys: :atoms!) do
      {:ok, decoded} -> decoded
      err -> IO.inspect(err); nil
    end
  end

  defp command(command) do
    case Redix.command(:"redix_#{random_index()}", command) do
      {:ok, val} -> val
      _ -> nil
    end
  end

  defp pipeline(commands) do
    case Redix.pipeline(:"redix_#{random_index()}", commands) do
      {:ok, vals} -> vals
      _ -> Enum.map(commands, fn(_) -> nil end)
    end
  end

  defp random_index() do
    rem(System.unique_integer([:positive]), 5)
  end
end
