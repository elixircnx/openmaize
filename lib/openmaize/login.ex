defmodule Openmaize.Login do
  @moduledoc """
  Module to handle login.

  There are four options:

    * storage - store the token in a cookie, which is the default, or not have Openmaize handle the storage
      * if you are developing an api or want to store the token in sessionStorage, set storage to nil
    * unique_id - the name which is used to identify the user (in the database)
      * the default is `:username`
      * this can also be a function which checks the user input and returns an atom
        * see the Openmaize.Login.Name module for some example functions
    * add_jwt - the function used to add the JSON Web Token to the response
      * the default is `&OpenmaizeJWT.Plug.add_token/5`
    * override_exp - set the default number of minutes that a token is valid for (overriding the default)
      * the default token validity is set in the OpenmaizeJWT config
      * the default is nil (no override)

  ## Remember me

  By using the `override_exp` option, you can override the default token
  validity on a case-by-case basis. This can help you implement a `remember
  me` option on the login page.

  It is recommended that `override_exp` is not set too high (in the example
  below, it is set to 10_080 [7 days]). In addition, it should not be used
  when protecting high, or even medium, value resources.

  ## Examples with Phoenix

  If you have used the `mix openmaize.gen.phoenixauth` command to generate
  an Authorize module, the `login_user` function in the examples below
  will simply call the `Authorize.handle_login` function.

  In the `web/router.ex` file, add the following line (you can use
  a different controller and route):

      post "/login", PageController, :login_user

  And then in the `page_controller.ex` file, add:

      plug Openmaize.Login when action in [:login_user]

  If you want to use `email` to identify the user:

      plug Openmaize.Login, [unique_id: :email] when action in [:login_user]

  If you want to use `email` or `username` to identify the user (allowing the
  end user a choice):

      plug Openmaize.Login, [unique_id: &Openmaize.Login.Name.email_username/1] when action in [:login_user]

  And if you want to override the default value for token validity, to
  implement a 'remember me' functionality, for example:

      plug Openmaize.Login, [override_exp: 10_080] when action in [:login_user]

  The above command creates a token that is valid for 7 days (10080 minutes)
  if "remember_me" in the user_params is set to true.
  """

  import Plug.Conn
  alias Openmaize.Config

  def init(opts) do
    {Keyword.get(opts, :storage, :cookie),
     Keyword.get(opts, :unique_id, :username),
     Keyword.get(opts, :add_jwt, &OpenmaizeJWT.Plug.add_token/5),
     Keyword.get(opts, :override_exp)}
  end

  @doc """
  Handle the login POST request.

  If the login is successful and `otp_required: true` is not in the
  user model, a JSON Web Token will be added to the conn, either in
  a cookie or in the body of the response. The conn is then returned.

  If `otp_required: true` is in the user model, `conn.private.openmaize_otp_required`
  will be set to true, but no token will be issued yet.
  """
  def call(%Plug.Conn{params: %{"user" =>
     %{"remember_me" => "true"} = user_params}} = conn, opts) do
    handle_login conn, user_params, opts
  end
  def call(%Plug.Conn{params: %{"user" => user_params}} = conn,
   {storage, uniq_id, add_jwt, _}) do
    handle_login conn, user_params, {storage, uniq_id, add_jwt, nil}
  end

  defp handle_login(conn, user_params, {storage, uniq_id, add_jwt, override_exp}) do
    {uniq, user_id, password} = get_params(user_params, uniq_id)
    Config.db_module.find_user(user_id, uniq)
    |> check_pass(password, Config.hash_name)
    |> handle_auth(conn, {storage, uniq, add_jwt, override_exp})
  end

  defp get_params(%{"password" => password} = user_params, uniq) when is_atom(uniq) do
    {uniq, Map.get(user_params, to_string(uniq)), password}
  end
  defp get_params(user_params, uniq_func), do: uniq_func.(user_params)

  defp check_pass(nil, _, _), do: Config.crypto_mod.dummy_checkpw
  defp check_pass(%{confirmed_at: nil}, _, _),
    do: {:error, "You have to confirm your email address before continuing."}
  defp check_pass(user, password, hash_name) do
    %{^hash_name => hash} = user
    Config.crypto_mod.checkpw(password, hash) and {:ok, user}
  end

  defp handle_auth({:ok, %{id: id, otp_required: true}}, conn,
   {storage, uniq, _, override_exp}) do
    put_private(conn, :openmaize_otpdata, {storage, uniq, id, override_exp})
  end
  defp handle_auth({:ok, user}, conn, {storage, uniq, add_jwt, override_exp}) do
    add_jwt.(conn, user, storage, uniq, override_exp)
  end
  defp handle_auth({:error, message}, conn, _opts) do
    put_private(conn, :openmaize_error, message)
  end
  defp handle_auth(_, conn, _opts) do
    put_private(conn, :openmaize_error, "Invalid credentials")
  end
end
