defmodule Mailer.Emails do
  import Bamboo.Email
  use Bamboo.Phoenix, view: Mailer.EmailView

  def weekly_podcast_snapshot(podcast_id) do
    IO.puts "looking up podcast_id #{podcast_id}"

    new_email()
    |> to("foo@example.com")
    |> from("us@example.com")
    |> subject("Weekly Podcast Report")
    |> put_text_layout({Mailer.LayoutView, "email.text"})
    |> render("weekly_snapshot.text", podcast_id: podcast_id)
    |> put_html_layout({Mailer.LayoutView, "email.html"})
    |> render("weekly_snapshot.html", podcast_id: podcast_id)

  end
end

