defmodule Castle.RedisCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      def redis_keys(pattern), do: Castle.Redis.Conn.command(~w(KEYS #{pattern}))

      def redis_count(pattern), do: length redis_keys(pattern)

      def redis_clear(pattern), do: redis_keys(pattern) |> Enum.map(&Castle.Redis.Conn.del/1)
    end
  end
end
