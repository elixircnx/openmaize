defmodule <%= base %>.SessionControllerTest do
  use <%= base %>.ConnCase

  import <%= base %>.OpenmaizeEcto<%= if confirm do %>

  @valid_link "email=arthur%40mail.com&key=pu9-VNdgE8V9qZo19rlcg3KUNjpxuixg"
  @invalid_link "email=arthur%40mail.com&key=pu9-VNdgE8V9QzO19RLCG3KUNjpxuixg"

  @valid_attrs %{username: "robin", password: "mangoes&g0oseberries"}
  @invalid_attrs %{username: "robin", password: "maaaangoes&g00zeberries"}

  setup %{conn: conn} do
    conn = conn |> bypass_through(<%= base %>.Router, :browser) |> get("/")

    add_user("arthur")
    confirmed = add_user_confirmed("robin")

    {:ok, %{conn: conn, confirmed: confirmed}}
  end

  test "login succeeds", %{conn: conn} do
    conn = post conn, session_path(conn, :create), user: @valid_attrs
    assert redirected_to(conn) == user_path(conn, :index)
  end

  test "login fails", %{conn: conn} do
    conn = post conn, session_path(conn, :create), user: @invalid_attrs
    assert redirected_to(conn) == session_path(conn, :new)
  end

  test "logout succeeds", %{conn: conn, confirmed: confirmed} do
    conn = conn |> put_session(:user_id, confirmed.id) |> send_resp(:ok, "/")
    conn = delete conn, session_path(conn, :delete, confirmed)
    assert redirected_to(conn) == page_path(conn, :index)
  end

  test "confirmation succeeds for correct key", %{conn: conn} do
    email = "arthur%40mail.com"
    key = "pu9-VNdgE8V9qZo19rlcg3KUNjpxuixg"
    conn = get(conn, session_path(conn, :confirm_email, email: email, key: key))
    #conn = get(conn, "/confirm_email?" <> @valid_link)
    assert conn.private.phoenix_flash["info"] =~ "successfully confirmed"
    assert redirected_to(conn) == session_path(conn, :new)
  end

  test "confirmation fails for incorrect key", %{conn: conn} do
    email = "arthur%40mail.com"
    key = "pu9-VNdgE8V9QzO19RLCG3KUNjpxuixg"
    conn = get(conn, session_path(conn, :confirm_email, email: email, key: key))
    #conn = get(conn, "/confirm_email?" <> @invalid_link)
    assert conn.private.phoenix_flash["error"] =~ "failed"
    assert redirected_to(conn) == session_path(conn, :new)
  end<% end %>

end
