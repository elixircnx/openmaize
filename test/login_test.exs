defmodule Openmaize.LoginTest do
  use Openmaize.TestCase
  use Plug.Test

  alias Openmaize.{DummyCrypto, TestRepo, TestUser, UserHelpers}

  setup do
    {:ok, _} = UserHelpers.add_user()
    {:ok, _} = UserHelpers.add_confirmed()
    :ok
  end

  def login(name, password, uniq \\ :email, user_params \\ "email") do
    conn(:post, "/login",
         %{"session" => %{user_params => name, "password" => password}})
    |> Openmaize.Login.call({uniq, user_params, TestRepo, TestUser})
  end

  def phone_name(%{"email" => email, "password" => password}) do
    {Regex.match?(~r/^[0-9]+$/, email) and :phone || :email, email, password}
  end

  test "init function" do
    assert Openmaize.Login.init([]) == {:email, "email", Openmaize.Repo, Openmaize.User}
  end

  test "login succeeds with username" do
    conn = login("ray", "h4rd2gU3$$", :username, "username")
    %{username: username} = conn.private[:openmaize_user]
    assert username == "ray"
  end

  test "login succeeds with email" do
    conn = login("ray@mail.com", "h4rd2gU3$$")
    %{email: email} = conn.private[:openmaize_user]
    assert email == "ray@mail.com"
  end

  test "login fails when crypto mod changes" do
    Application.put_env(:openmaize, :crypto_mod, DummyCrypto)
    conn = login("ray", "h4rd2gU3$$")
    assert conn.private[:openmaize_error]
  after
    Application.delete_env(:openmaize, :crypto_mod)
  end

  test "login fails for incorrect password" do
    conn = login("ray", "oohwhatwasitagain")
    assert conn.private[:openmaize_error] =~ "Invalid credentials"
  end

  test "login fails when account is not yet confirmed" do
    conn = login("fred", "mangoes&g0oseberries", :username, "username")
    assert conn.private[:openmaize_error] =~ "have to confirm your account"
  end

  test "login fails for invalid username" do
    conn = login("dick", "h4rd2gU3$$", :username, "username")
    assert conn.private[:openmaize_error] =~ "Invalid credentials"
  end

  test "login fails for invalid email" do
    conn = login("dick@mail.com", "h4rd2gU3$$")
    assert conn.private[:openmaize_error] =~ "Invalid credentials"
  end

  test "function unique_id with email" do
    conn = login("ray@mail.com", "h4rd2gU3$$", &phone_name/1, "email")
    %{email: email} = conn.private[:openmaize_user]
    assert email == "ray@mail.com"
  end

  test "function unique_id with phone" do
    conn = login("081555555", "h4rd2gU3$$", &phone_name/1, "email")
    %{email: email} = conn.private[:openmaize_user]
    assert email == "ray@mail.com"
  end

  test "output to current_user does not contain password_hash or otp_secret" do
    conn = login("ray", "h4rd2gU3$$", :username, "username")
    user = conn.private[:openmaize_user]
    refute Map.has_key?(user, :password_hash)
    refute Map.has_key?(user, :otp_secret)
  end

end
