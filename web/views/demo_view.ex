defmodule Porter.DemoView do

  def render("index.json", %{programs: programs}) do
    %{
      programs: Enum.map(programs, &demo_json/1)
    }
  end

  defp demo_json(program) do
    %{
      name: program.program,
      impressions: program.count,
    }
  end

end
