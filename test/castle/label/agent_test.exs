defmodule Castle.CastleLabelAgentTest do
  use Castle.ConnCase, async: true

  import Castle.Label.Agent

  test "gets agent names" do
    assert agent_name(3) == "Alexa"
  end

  test "gets agent types" do
    assert agent_type(36) == "Mobile App"
  end

  test "gets agent os" do
    assert agent_os(43) == "iOS"
  end

  test "gets unknowns" do
    assert agent_name(0) == "Unknown"
    assert agent_type(123456) == "Unknown"
    assert agent_os(9999999) == "Unknown"
  end

end
