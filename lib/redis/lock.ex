defmodule Castle.Redis.Lock do

  defmacro lock(key, ttl, do: expression) do
    quote do
      lock(unquote(key), unquote(ttl), 0, do: unquote(expression))
    end
  end
  defmacro lock(key, ttl, success_ttl, do: expression) do
    quote do
      if get_lock(unquote(key), unquote(ttl)) do
        try do
          result = unquote(expression)
          remove_lock(unquote(key), unquote(success_ttl))
          result
        rescue
          err ->
            remove_lock(unquote(key), 0)
            raise err
        end
      else
        :locked
      end
    end
  end

  def get_lock(key, ttl) do
    Castle.Redis.Conn.setnx(key, ttl, "locked")
  end

  def is_locked?(key) do
    case Castle.Redis.Conn.get(key) do
      "locked" -> true
      "unlocking" -> true
      _ -> false
    end
  end

  def is_unlocking?(key) do
    case Castle.Redis.Conn.get(key) do
      "unlocking" -> true
      _ -> false
    end
  end

  def remove_lock(key, 0) do
    Castle.Redis.Conn.del(key)
  end
  def remove_lock(key, final_ttl) do
    Castle.Redis.Conn.set(key, final_ttl, "unlocking")
  end
end
