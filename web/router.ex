defmodule Porter.Router do
  use Porter.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # scope "/", Porter do
  #   pipe_through :browser # Use the default browser stack
  #
  #   get "/", RedirectController, :index
  # end

  scope "/", Porter do
    pipe_through :api

    get "/", RedirectController, :index
    get "/api", RedirectController, :index
  end

  scope "/api/v1", Porter.API, as: :api do
    pipe_through :api

    get "/", RootController, :index
    resources "/podcasts", PodcastController, only: [:index, :show]
    resources "/episodes", EpisodeController, only: [:index, :show]
    get "/podcasts/:id/downloads", PodcastController, :downloads
    get "/podcasts/:id/impressions", PodcastController, :impressions
    get "/episodes/:id/downloads", EpisodeController, :downloads
    get "/episodes/:id/impressions", EpisodeController, :impressions
  end

end
