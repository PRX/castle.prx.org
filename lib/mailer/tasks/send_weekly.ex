defmodule Mix.Tasks.Mailer.SendWeekly do
  use Mix.Task

  @shortdoc "Sends the weekly report to metrics users."
  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [podcast_id: :integer, email_address: :binary]
    send_email(opts)

  end

  def send_email([podcast_id: podcast_id, email_address: email_address]) do
    IO.inspect Mailer.Emails.weekly_podcast_snapshot(podcast_id, email_address)
  end

  def send_email(_args) do
    IO.puts "\n\nusage: `mix send.weekly --podcast_id 3`\n\n"

  end

end
