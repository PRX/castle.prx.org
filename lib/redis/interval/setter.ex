defmodule Castle.Redis.Interval.Setter do
  alias Castle.Redis.Conn, as: Conn
  alias Castle.Redis.Interval.Keys, as: Keys

  @past_interval_ttl 0 # forever
  @current_interval_ttl 300
  @current_interval_buffer 3600

  def past_interval_ttl, do: @past_interval_ttl
  def current_interval_ttl, do: @current_interval_ttl

  def set(_key_prefix, _from, _to, []), do: []
  def set(key_prefix, from, to, counts) do
    key = Keys.key(key_prefix, from)
    ttl = interval_ttl(to)
    Conn.hsetall(key, counts, ttl)
  end

  def interval_ttl(interval_end) do
    cutoff = Timex.now() |> Timex.shift(seconds: -@current_interval_buffer)
    if Timex.compare(cutoff, interval_end) < 0 do
      @current_interval_ttl
    else
      @past_interval_ttl
    end
  end
end
