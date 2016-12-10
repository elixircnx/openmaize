defmodule <%= base %>.Router do
  use <%= base %>.Web, :router
<%= if api do %>
  import <%= base %>.Auth

  pipeline :api do
    plug :accepts, ["json"]
    plug :verify_token
  end

  scope "/api", <%= base %> do
    pipe_through :api

    post "/sessions/create", SessionController, :create
    resources "/users", UserController, except: [:new, :edit]
  end
<% else %>
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Openmaize.Authenticate
  end

  scope "/", <%= base %> do
    pipe_through :browser

    get "/", PageController, :index

    resources "/users", UserController
    resources "/sessions", SessionController, only: [:new, :create, :delete]<%= if confirm do %>
    get "/sessions/confirm_email", SessionController, :confirm_email
    resources "/password_resets", PasswordResetController, only: [:new, :create, :edit, :update]<% end %>
  end
<% end %>
end
