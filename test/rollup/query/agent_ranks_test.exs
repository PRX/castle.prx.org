defmodule Castle.RollupQueryAgentRanksTest do
  use Castle.DataCase
  use Castle.TimeHelpers

  import Castle.Rollup.Query.AgentRanks

  @id 70
  @guid1 "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  @guid2 "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

  setup do
    Castle.DailyAgent.upsert %{podcast_id: @id, episode_id: @guid1, count: 11,
      day: ~D[2018-04-24], agent_name_id: 1001, agent_type_id: 2001, agent_os_id: 3001}
    Castle.DailyAgent.upsert %{podcast_id: @id, episode_id: @guid1, count: 22,
      day: ~D[2018-04-24], agent_name_id: 1002, agent_type_id: 2002, agent_os_id: 3002}
    Castle.DailyAgent.upsert %{podcast_id: @id, episode_id: @guid2, count: 33,
      day: ~D[2018-04-24], agent_name_id: 1003, agent_type_id: 2003, agent_os_id: 3003}
    Castle.DailyAgent.upsert %{podcast_id: @id, episode_id: @guid2, count: 44,
      day: ~D[2018-04-25], agent_name_id: 1004, agent_type_id: 2004, agent_os_id: 3004}
    Castle.DailyAgent.upsert %{podcast_id: @id, episode_id: @guid2, count: 55,
      day: ~D[2018-04-25], agent_name_id: 1001, agent_type_id: 2001, agent_os_id: 3001}
    Castle.DailyAgent.upsert %{podcast_id: @id, episode_id: @guid1, count: 66,
      day: ~D[2018-04-25], agent_name_id: 0, agent_type_id: 0, agent_os_id: 0}
    [t1: get_dtim("2018-04-24T00:00:00"), t2: get_dtim("2018-04-26T00:00:00")]
  end

  describe "agentname" do

    test "ranks a podcast", %{t1: t1, t2: t2} do
      {ranks, datas} = podcast(@id, t1, t2, "day", "agentname", 2)
      assert ranks == [1001, 0, nil]
      assert length(datas) == 5
      assert_result datas, 0, 1001, 11, "2018-04-24"
      assert_result datas, 1, nil, 55, "2018-04-24"
      assert_result datas, 2, 0, 66, "2018-04-25"
      assert_result datas, 3, 1001, 55, "2018-04-25"
      assert_result datas, 4, nil, 44, "2018-04-25"
    end

    test "ranks an episode", %{t1: t1, t2: t2} do
      {ranks, datas} = episode(@guid1, t1, t2, "day", "agentname", 2)
      assert ranks == [0, 1002, nil]
      assert length(datas) == 3
      assert_result datas, 0, 1002, 22, "2018-04-24"
      assert_result datas, 1, nil, 11, "2018-04-24"
      assert_result datas, 2, 0, 66, "2018-04-25"
    end

  end

  describe "agenttype" do

    test "ranks a podcast", %{t1: t1, t2: t2} do
      {ranks, datas} = podcast(@id, t1, t2, "day", "agenttype", 2)
      assert ranks == [2001, 0, nil]
      assert length(datas) == 5
      assert_result datas, 0, 2001, 11, "2018-04-24"
      assert_result datas, 1, nil, 55, "2018-04-24"
      assert_result datas, 2, 0, 66, "2018-04-25"
      assert_result datas, 3, 2001, 55, "2018-04-25"
      assert_result datas, 4, nil, 44, "2018-04-25"
    end

    test "ranks an episode", %{t1: t1, t2: t2} do
      {ranks, datas} = episode(@guid1, t1, t2, "day", "agenttype", 2)
      assert ranks == [0, 2002, nil]
      assert length(datas) == 3
      assert_result datas, 0, 2002, 22, "2018-04-24"
      assert_result datas, 1, nil, 11, "2018-04-24"
      assert_result datas, 2, 0, 66, "2018-04-25"
    end

  end

  describe "agentos" do

    test "ranks a podcast", %{t1: t1, t2: t2} do
      {ranks, datas} = podcast(@id, t1, t2, "day", "agentos", 2)
      assert ranks == [3001, 0, nil]
      assert length(datas) == 5
      assert_result datas, 0, 3001, 11, "2018-04-24"
      assert_result datas, 1, nil, 55, "2018-04-24"
      assert_result datas, 2, 0, 66, "2018-04-25"
      assert_result datas, 3, 3001, 55, "2018-04-25"
      assert_result datas, 4, nil, 44, "2018-04-25"
    end

    test "ranks an episode", %{t1: t1, t2: t2} do
      {ranks, datas} = episode(@guid1, t1, t2, "day", "agentos", 2)
      assert ranks == [0, 3002, nil]
      assert length(datas) == 3
      assert_result datas, 0, 3002, 22, "2018-04-24"
      assert_result datas, 1, nil, 11, "2018-04-24"
      assert_result datas, 2, 0, 66, "2018-04-25"
    end

  end

  defp assert_result(datas, index, group, count, date_str) do
    assert Enum.at(datas, index).group == group
    assert Enum.at(datas, index).count == count
    assert_time Enum.at(datas, index).time, "#{date_str}T00:00:00Z"
  end

end
