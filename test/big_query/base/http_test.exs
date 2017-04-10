defmodule Porter.BigQueryBaseHTTPTest do
  use Porter.BigQueryCase, async: false

  import Mock
  import BigQuery.Base.HTTP

  @tag :external
  test "gets bigquery data" do
    %{"kind" => kind, "datasets" => datasets} = get("datasets")
    assert kind == "bigquery#datasetList"
    assert is_list datasets
  end

  @tag :external
  test "handles post errors" do
    assert_raise RuntimeError, ~r/bigquery 400/i, fn ->
      post("datasets", %{})
    end
  end

  test "memoizes auth tokens" do
    fake_token = [get_token: fn() -> {:ok, UUID.uuid4(), :os.system_time(:seconds) + 999} end]
    with_mock BigQuery.Base.Auth, fake_token do
      assert {:ok, token1} = get_token()
      assert {:ok, token2} = get_token()
      assert token1 == token2
    end
  end

  test "expires auth tokens" do
    fake_token = [get_token: fn() -> {:ok, UUID.uuid4(), :os.system_time(:seconds) - 1} end]
    with_mock BigQuery.Base.Auth, fake_token do
      assert {:ok, token1} = get_token()
      assert {:ok, token2} = get_token()
      refute token1 == token2
    end
  end
end
