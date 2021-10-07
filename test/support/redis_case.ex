defmodule Castle.RedisCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @redis Application.get_env(:castle, :redis_library)

      def redis_clear(pattern), do: @redis.nuke(pattern)
    end
  end
end
