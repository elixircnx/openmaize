defmodule <%= base %>.Authorize do

  import Plug.Conn
  import Phoenix.Controller

  @redirects %{"admin" => "/admin", "user" => "/users", nil => "/"}

  @doc """
  Custom action that can be used to override the `action` function in any
  Phoenix controller.

  This function checks for a `current_user` value. If there is no current_user,
  the `unauthenticated` function is called.

  ## Examples

  First, import this module in the controller, and then add the following line:

      def action(conn, _), do: authorize_action conn, __MODULE__

  This command will only allow connections for users with the "admin" or "user"
  role.

  You will also need to change the other functions in the controller to accept
  a third argument, which is the current user. For example, change:
  `def index(conn, params) do` to: `def index(conn, params, user) do`
  """
  def authorize_action(%Plug.Conn{assigns: %{current_user: nil}} = conn, _, _) do
    unauthenticated conn
  end
  def authorize_action(%Plug.Conn{assigns: %{current_user: current_user},
    params: params} = conn, module) do
    apply(module, action_name(conn), [conn, params, current_user])
  end

  @doc """
  Similar to `authorize_action`, but the user's role is also checked to
  make sure it is in the list of authorized roles.

  This function checks for a `current_user` value, and if it finds it, it
  then checks that the user's role is in the list of allowed roles. If
  there is no current_user, the `unauthenticated` function is called, and
  if the user's role is not in the list of allowed roles, the `unauthorized`
  function is called.

  ## Examples

  First, import this module in the controller, and then add the following line:

      def action(conn, _), do: authorize_action_role conn, ["admin", "user"], __MODULE__

  This command will only allow connections for users with the "admin" or "user"
  role.

  You will also need to change the other functions in the controller to accept
  a third argument, which is the current user. For example, change:
  `def index(conn, params) do` to: `def index(conn, params, user) do`
  """
  def authorize_action_role(%Plug.Conn{assigns: %{current_user: nil}} = conn, _, _) do
    unauthenticated conn
  end
  def authorize_action_role(%Plug.Conn{assigns: %{current_user: current_user},
    params: params} = conn, roles, module) do
    if current_user.role in roles do
      apply(module, action_name(conn), [conn, params, current_user])
    else
      unauthorized conn, current_user
    end
  end

  @doc """
  Redirect an unauthenticated user to the login page.
  """
  def unauthenticated(conn, message \\ "You need to log in to view this page") do
    conn
    |> put_flash(:error, message)
    |> redirect(to: "/login")
    |> halt
  end

  @doc """
  Redirect an unauthorized user to that user's role's page.

  If you are not using roles, you will need to edit this function
  before using it.

  Each role has a redirect page associated with it, and these are set in the
  `@redirects` module attribute in this file.
  """
  def unauthorized(conn, current_user, message \\ "You are not authorized to view this page") do
    conn
    |> put_flash(:error, message)
    |> redirect(to: @redirects[current_user.role])
    |> halt
  end

  @doc """
  Check, based on role, that the user is authorized to access this resource.

  ## Examples

  First, import this module, and then add the following line to the controller:

      plug :role_check, [roles: "admin", "user"] when action in [:show, :edit]

  This command will check the user's role for the `show` and `edit` routes.
  """
  def role_check(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts) do
    unauthenticated conn
  end
  def role_check(%Plug.Conn{assigns: %{current_user: current_user}} = conn, opts) do
    roles = Keyword.get(opts, :roles, [])
    current_user.role in roles and conn || unauthorized conn, current_user
  end

  @doc """
  Check, based on user id, that the user is authorized to access this resource.

  ## Examples

  First, import this module, and then add the following line to the controller:

      plug :id_check when action in [:show, :edit, :update]

  This command will check the user id for the `show`, `edit` and `update` routes.
  """
  def id_check(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts) do
    unauthenticated conn
  end
  def id_check(%Plug.Conn{params: %{"id" => id}, assigns: %{current_user:
     %{id: current_id} = current_user}} = conn, _opts) do
    id == to_string(current_id) and conn || unauthorized conn, current_user
  end

  @doc """
  Login and redirect to the user's role's page if successful.

  If you are not using roles, you will need to edit this function
  before using it.

  ## Examples

  Add the following line to the controller which handles login:

      plug Openmaize.Login, [db_module: <%= base %>.OpenmaizeEcto] when action in [:login_user]

  and then call `handle_login` from the `login_user` function:

      def login_user(conn, params), do: handle_login(conn, params)

  See the documentation for Openmaize.Login for all the login options.

  ## Two factor authentication

  This function can also be used for two factor authentication for any
  user with `otp_required` set to true.
  """
  def handle_login(%Plug.Conn{private: %{openmaize_error: message}} = conn, _params) do
    unauthenticated conn, message
  end
  def handle_login(%Plug.Conn{private: %{openmaize_otpdata: id}} = conn, _) do
    render conn, "twofa.html", id: id
  end
  def handle_login(%Plug.Conn{private: %{openmaize_user: %{id: id, role: role, remember: true}}} = conn,
   %{"user" => %{"remember_me" => "true"}}) do
    conn
    |> Openmaize.Remember.add_cookie(id)
    |> put_flash(:info, "You have been logged in")
    |> redirect(to: @redirects[role])
  end
  def handle_login(%Plug.Conn{private: %{openmaize_user: %{id: id, role: role}}} = conn, _params) do
    conn
    |> put_session(:user_id, id)
    |> put_flash(:info, "You have been logged in")
    |> redirect(to: @redirects[role])
  end

  @doc """
  Logout and redirect to the home page.

  This example also deletes the remember_me cookie if it is present.
  """
  def handle_logout(conn, _params) do
    configure_session(conn, drop: true)
    |> Openmaize.Remember.delete_rem_cookie
    |> put_flash(:info, "You have been logged out")
    |> redirect(to: "/")
  end
end
