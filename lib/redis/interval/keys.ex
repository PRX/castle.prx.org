defmodule Castle.Redis.Interval.Keys do
  def keys(prefix, date_range) do
    Enum.map(date_range, &(key(prefix, &1)))
  end

  def key(prefix, dtim) do
    "#{prefix}.#{format(dtim)}"
  end

  defp format(dtim) do
    {:ok, formatted} = Timex.format(dtim, "{ISO:Extended:Z}")
    formatted
  end
end
