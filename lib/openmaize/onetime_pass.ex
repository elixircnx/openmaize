defmodule Openmaize.OnetimePass do
  @moduledoc """
  Module to handle one-time passwords for use in two factor authentication.

  There are two options related to the database:

    * repo - the name of the repo
      * the default is MyApp.Repo - using the name of the project
    * user_model - the name of the user model
      * the default is MyApp.User - using the name of the project

  There are also the following options for the one-time passwords:

    * HMAC-based one-time passwords
      * token_length - the length of the one-time password
        * the default is 6
      * last - the count when the one-time password was last used
        * this count needs to be stored server-side
      * window - the number of future attempts allowed
        * the default is 3
    * Time-based one-time passwords
      * token_length - the length of the one-time password
        * the default is 6
      * interval_length - the length of each timed interval
        * the default is 30 (seconds)
      * window - the number of attempts, before and after the current one, allowed
        * the default is 1 (1 interval before and 1 interval after)

  See the documentation for the Comeonin.Otp module for more details
  about generating and verifying one-time passwords.

  ## Examples

  Add the following line to your controller to call OnetimePass with the
  default values:

      plug Openmaize.OnetimePass when action in [:login_twofa]

  And to set the token length to 8 characters:

      plug Openmaize.OnetimePass, [token_length: 8] when action in [:login_twofa]

  """

  @behaviour Plug

  import Plug.Conn
  alias Comeonin.Otp

  def init(opts) do
    {Keyword.get(opts, :repo, Openmaize.Utils.default_repo),
    Keyword.get(opts, :user_model, Openmaize.Utils.default_user_model),
    opts}
  end

  @doc """
  Handle the one-time password POST request.

  If the one-time password check is successful, the user will be added
  to the session.
  """
  def call(%Plug.Conn{params: %{"user" => %{"id" => id} = user_params}} = conn,
  {repo, user_model, opts}) do
    repo.get(user_model, id)
    |> check_key(user_params, opts)
    |> handle_auth(conn)
  end

  defp check_key(user, %{"hotp" => hotp}, opts) do
    {user, Otp.check_hotp(hotp, user.otp_secret, [last: user.otp_last] ++ opts)}
  end
  defp check_key(user, %{"totp" => totp}, opts) do
    {user, Otp.check_totp(totp, user.otp_secret, opts)}
  end

  defp handle_auth({_, false}, conn) do
    put_private(conn, :openmaize_error, "Invalid credentials")
  end
  defp handle_auth({%{otp_last: otp_last} = user, last}, conn)
  when last > otp_last do
    put_private(conn, :openmaize_user, %{user | otp_last: last})
  end
  defp handle_auth(_, conn) do
    put_private(conn, :openmaize_error, "Invalid credentials")
  end
end
