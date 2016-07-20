defmodule Openmaize.OnetimePass do
  @moduledoc """
  Module to handle one-time passwords for use in two factor authentication.

  There is one option:

    * db_module - the module that is used to query the database
      * in most cases, this will be generated by `mix openmaize.gen.ectodb` and will be called MyApp.OpenmaizeEcto
      * if you implement your own database module, it needs to implement the Openmaize.Database behaviour

      ALSO OPTIONS FOR OTP
  """

  import Openmaize.OnetimePass.Base

  @behaviour Plug

  def init(opts) do
    {db_module, opts} = Keyword.pop opts, :db_module
    {auth_func, otp_opts} = Keyword.pop opts, :auth_func, :session
    {db_module, auth_func, otp_opts}
  end

  @doc """
  Handle the one-time password POST request.

  If the one-time password check is successful, the user will be added
  to the session.
  """
  def call(_, {nil, _, _}) do
    raise ArgumentError, "You need to set the db_module value for Openmaize.OnetimePass"
  end
  def call(%Plug.Conn{params: %{"user" => %{"id" => id, "uniq" => uniq} = user_params}} = conn,
   {db_module, auth_func, opts}) do
    db_module.find_user_byid(id)
    |> check_key(user_params, opts)
    |> handle_auth(conn, auth_func, uniq)
  end
end
