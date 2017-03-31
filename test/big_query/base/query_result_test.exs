defmodule Porter.BigQueryBaseQueryResultTest do
  use Porter.BigQueryCase, async: true

  import BigQuery.Base.QueryResult

  test "handles 0-length results" do
    result = from_response(%{"rows" => [], "schema" => %{"fields" => []}})
    assert is_list result
    assert length(result) == 0
  end

  test "handles null results" do
    result = from_response(%{"schema" => %{"fields" => []}})
    assert is_list result
    assert length(result) == 0
  end

  test "names result fields based on the schema" do
    result = from_response(%{
      "rows" => [%{"f" => [
        %{"v" => "something"},
        %{"v" => "okay"},
      ]}],
      "schema" => %{"fields" => [
        %{"name" => "foo", "type" => "STRING"},
        %{"name" => "bar", "type" => "STRING"},
      ]}
    })

    assert is_list result
    assert length(result) == 1
    assert hd(result).foo == "something"
    assert hd(result).bar == "okay"
  end

  test "casts field types based on the schema" do
    result = from_response(%{
      "rows" => [%{"f" => [
        %{"v" => "string"},
        %{"v" => "true"},
        %{"v" => "false"},
        %{"v" => "1234"},
        %{"v" => "1490219692"},
        %{"v" => "1.490219692E9"},
      ]}],
      "schema" => %{"fields" => [
        %{"name" => "string", "type" => "STRING"},
        %{"name" => "istrue", "type" => "BOOLEAN"},
        %{"name" => "isfalse", "type" => "BOOLEAN"},
        %{"name" => "int", "type" => "INTEGER"},
        %{"name" => "stampint", "type" => "TIMESTAMP"},
        %{"name" => "stampfloat", "type" => "TIMESTAMP"},
      ]}
    })

    assert is_list result
    assert length(result) == 1
    assert hd(result).string == "string"
    assert hd(result).istrue == true
    assert hd(result).isfalse == false
    assert hd(result).int == 1234
    {:ok, time, _} = DateTime.from_iso8601("2017-03-22T21:54:52Z")
    assert hd(result).stampint == time
    assert hd(result).stampfloat == time
  end

  test "handles null values" do
    result = from_response(%{
      "rows" => [%{"f" => [%{"v" => nil}, %{"v" => nil}, %{"v" => nil}, %{"v" => nil}]}],
      "schema" => %{"fields" => [
        %{"name" => "string", "type" => "STRING"},
        %{"name" => "bool", "type" => "BOOLEAN"},
        %{"name" => "int", "type" => "INTEGER"},
        %{"name" => "stamp", "type" => "TIMESTAMP"},
      ]}
    })

    assert is_list result
    assert length(result) == 1
    assert hd(result).string == nil
    assert hd(result).bool == nil
    assert hd(result).int == nil
    assert hd(result).stamp == nil
  end
end
