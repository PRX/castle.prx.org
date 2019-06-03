defmodule Castle.BigQueryRollupDailyAgentsTest do
  use Castle.BigQueryCase

  import BigQuery.Rollup.DailyAgents

  test_with_bq "gets empty agents in the past", [] do
    meta = query get_dtim("2016-01-01T05:04:00Z"), fn(results) ->
      assert length(results) == 0
    end
    assert_time meta.day, "2016-01-01T00:00:00Z"
    assert meta.complete == true
  end

  test "gets empty agents in the future" do
    meta = query get_dtim("2030-01-01"), fn(results) ->
      assert length(results) == 0
    end
    assert_time meta.day, "2030-01-01T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 0
  end

  test_with_bq "gets a partial day of agents", "2017-05-01T05:14:37Z", [
    %{podcast_id: 1, episode_id: "a", agent_name_id: 1, agent_type_id: 2, agent_os_id: 3, count: 123},
    %{podcast_id: 2, episode_id: "b", agent_name_id: 1, agent_type_id: 2, agent_os_id: 3, count: 456},
    %{podcast_id: 1, episode_id: "a", agent_name_id: 1, agent_type_id: 2, agent_os_id: 3, count: 789},
  ] do
    meta = query get_dtim("2017-05-01"), fn(results) ->
      assert length(results) == 3
      assert hd(results).podcast_id == 1
      assert hd(results).episode_id == "a"
      assert hd(results).agent_name_id == 1
      assert hd(results).agent_type_id == 2
      assert hd(results).agent_os_id == 3
      assert hd(results).count == 123
      assert hd(results).day == ~D[2017-05-01]
    end
    assert_time meta.day, "2017-05-01T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 4
  end

  @tag :external
  test "actually gets data" do
    meta = query get_dtim("2017-05-01"), fn(results) ->
      assert length(results) == 1311
      assert hd(results).day == ~D[2017-05-01]
    end
    assert_time meta.day, "2017-05-01T00:00:00Z"
    assert meta.complete == true
  end
end
