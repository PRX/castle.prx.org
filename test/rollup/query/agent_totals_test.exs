defmodule Castle.RollupQueryAgentTotalsTest do
  use Castle.DataCase
  use Castle.TimeHelpers

  import Castle.Rollup.Query.AgentTotals

  @id 70
  @guid1 "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  @guid2 "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

  setup do
    Castle.DailyAgent.upsert %{podcast_id: @id, episode_id: @guid1, count: 11,
      day: ~D[2018-04-24], agent_name_id: 2001, agent_type_id: 2004, agent_os_id: 2007}
    Castle.DailyAgent.upsert %{podcast_id: @id, episode_id: @guid1, count: 22,
      day: ~D[2018-04-24], agent_name_id: 2002, agent_type_id: 2005, agent_os_id: 2008}
    Castle.DailyAgent.upsert %{podcast_id: @id, episode_id: @guid2, count: 33,
      day: ~D[2018-04-25], agent_name_id: 2003, agent_type_id: 2006, agent_os_id: 2009}
    [t1: get_dtim("2018-04-24T00:00:00"), t2: get_dtim("2018-04-26T00:00:00")]
  end

  describe "agentname" do

    test "totals a podcast", %{t1: t1, t2: t2} do
      totals = podcast(@id, t1, t2, "agentname")
      assert length(totals) == 3
      assert Enum.at(totals, 0).group == 2003
      assert Enum.at(totals, 0).count == 33
      assert Enum.at(totals, 1).group == 2002
      assert Enum.at(totals, 1).count == 22
      assert Enum.at(totals, 2).group == 2001
      assert Enum.at(totals, 2).count == 11
    end

    test "totals an episode", %{t1: t1, t2: t2} do
      totals = episode(@guid1, t1, t2, "agentname")
      assert length(totals) == 2
      assert Enum.at(totals, 0).group == 2002
      assert Enum.at(totals, 0).count == 22
      assert Enum.at(totals, 1).group == 2001
      assert Enum.at(totals, 1).count == 11
    end

  end

  describe "agenttype" do

    test "totals a podcast", %{t1: t1, t2: t2} do
      totals = podcast(@id, t1, t2, "agenttype")
      assert length(totals) == 3
      assert Enum.at(totals, 0).group == 2006
      assert Enum.at(totals, 0).count == 33
      assert Enum.at(totals, 1).group == 2005
      assert Enum.at(totals, 1).count == 22
      assert Enum.at(totals, 2).group == 2004
      assert Enum.at(totals, 2).count == 11
    end

    test "totals an episode", %{t1: t1, t2: t2} do
      totals = episode(@guid1, t1, t2, "agenttype")
      assert length(totals) == 2
      assert Enum.at(totals, 0).group == 2005
      assert Enum.at(totals, 0).count == 22
      assert Enum.at(totals, 1).group == 2004
      assert Enum.at(totals, 1).count == 11
    end

  end

  describe "agentos" do

    test "totals a podcast", %{t1: t1, t2: t2} do
      totals = podcast(@id, t1, t2, "agentos")
      assert length(totals) == 3
      assert Enum.at(totals, 0).group == 2009
      assert Enum.at(totals, 0).count == 33
      assert Enum.at(totals, 1).group == 2008
      assert Enum.at(totals, 1).count == 22
      assert Enum.at(totals, 2).group == 2007
      assert Enum.at(totals, 2).count == 11
    end

    test "totals an episode", %{t1: t1, t2: t2} do
      totals = episode(@guid1, t1, t2, "agentos")
      assert length(totals) == 2
      assert Enum.at(totals, 0).group == 2008
      assert Enum.at(totals, 0).count == 22
      assert Enum.at(totals, 1).group == 2007
      assert Enum.at(totals, 1).count == 11
    end

  end

end
