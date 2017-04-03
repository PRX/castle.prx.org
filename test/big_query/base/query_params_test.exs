defmodule Porter.BigQueryBaseQueryParamsTest do
  use Porter.BigQueryCase, async: true

  import BigQuery.Base.QueryParams

  test "sets parameter names" do
    params = parameterize(%{bar: 1, foo: 2, stuff: 3})
    assert is_list params
    assert length(params) == 3
    [one, two, three] = Enum.map(params, &(&1[:name]))
    assert one == :bar
    assert two == :foo
    assert three == :stuff
  end

  test "sets parameter values" do
    params = parameterize(%{bar: 1, foo: "b", stuff: ~D[2010-10-31]})
    assert is_list params
    assert length(params) == 3
    [one, two, three] = Enum.map(params, &(&1[:parameterValue][:value]))
    assert one == "1"
    assert two == "b"
    assert three == "2010-10-31"
  end

  test "guesses parameter types" do
    {:ok, time, _} = DateTime.from_iso8601("2017-03-22T21:54:52Z")
    date = ~D[2010-10-31]
    params = parameterize(%{a: time, b: 12, c: 12.2, d: false, e: "foo", f: nil, g: date})
    assert is_list params
    assert length(params) == 7
    [a, b, c, d, e, f, g] = Enum.map(params, &(&1[:parameterType][:type]))
    assert a == "TIMESTAMP"
    assert b == "INT64"
    assert c == "FLOAT64"
    assert d == "BOOL"
    assert e == "STRING"
    assert f == "STRING"
    assert g == "DATE"
  end
end
