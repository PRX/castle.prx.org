defmodule Castle.Redis.IntervalCache do
  alias Castle.Redis.Interval.{Getter, Setter}

  def interval(key_prefix, intv, ident, work_fn) do
    key_prefix = "#{key_prefix}.#{intv.rollup.name()}"
    case Getter.get(key_prefix, ident, intv.from, intv.to, intv.rollup) do
      {[], _new_from} ->
        {data, meta} = run_work(work_fn, intv, key_prefix, ident)
        {data, Map.put(meta, :cache_hits, 0)}
      {hits, nil} ->
        {hits, %{cached: true, cache_hits: length(hits)}}
      {hits, new_from} ->
        new_intv = Map.put(intv, :from, new_from)
        {data, meta} = run_work(work_fn, new_intv, key_prefix, ident)
        {hits ++ data, Map.put(meta, :cache_hits, length(hits))}
    end
  end

  def run_work(work_fn, intv, key_prefix, ident) do
    {data, meta} = work_fn.(intv)

    # bulk set all the %{ident => counts}
    Enum.each(data, fn({time, ids_to_counts}) ->
      Setter.set(key_prefix, time, intv.rollup.next(time), ids_to_counts)
    end)

    # filter down to the specific ident we want to return
    {filter_work(data, ident), meta}
  end

  def filter_work([{time, ids_to_counts} | rest], ident) do
    count = Map.get(ids_to_counts, ident, 0)
    [%{time: time, count: count}] ++ filter_work(rest, ident)
  end
  def filter_work([], _ident), do: []
end
