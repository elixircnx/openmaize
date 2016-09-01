defmodule Mix.Tasks.Openmaize.Gen.Phoenixauth do
  use Mix.Task

  @moduledoc """
  Create modules for authorization and, optionally, email confirmation.

  Warning - the following files are overwritten: web/controllers/page_controller.ex,
  web/controllers/user_controller.ex, web/router.ex and web/models/user.ex.
  You will be given the option not to overwrite when you run the command.

  ## Options

  There are three options:

    * confirm - add functions for email confirmation and password resets
      * the default is false
    * api - provide functions for an api, using OpenmaizeJWT and JSON Web Tokens
      * the default is false
    * ecto - use ecto for database interaction
      * the default is true

  ## Examples

  Run this command after running `mix phoenix.gen.html` or
  `mix phoenix.gen.json`.

  In the root directory of your project, run the following command
  (add the `--api` option if your app is for an api and / or the `--no-ecto`
  option if you are not using ecto):

      mix openmaize.gen.phoenixauth

  This command will create an Authorize module in the `web/controllers`
  directory and tests in the `test/controllers` directory.
  """

  @doc false
  def run(args) do
    switches = [confirm: :boolean, api: :boolean, ecto: :boolean]
    {opts, _argv, _} = OptionParser.parse(args, switches: switches)

    base = Openmaize.Utils.base_name
    srcdir = Path.join [Application.app_dir(:openmaize, "priv"),
     "templates", "phoenixauth"]

    files = [
      {:eex, "session_controller.ex", "web/controllers/session_controller.ex"},
      {:eex, "session_controller_test.exs", "test/controllers/session_controller_test.exs"},
      {:eex, "session_view.ex", "web/views/session_view.ex"},
      {:eex, "user_controller.ex", "web/controllers/user_controller.ex"},
      {:eex, "user_controller_test.exs", "web/controllers/user_controller_test.exs"},
      {:eex, "user_view.ex", "web/views/user_view.ex"},
      {:eex, "test_helpers.ex", "test/support/test_helpers.ex"},
      {:eex, "user_migration.exs", "priv/repo/migrations/#{timestamp()}_create_user.exs"},
      {:eex, "user_model.ex", "web/models/user.ex"},
      {:eex, "user_model_test.exs", "test/models/user.exs"},
      {:eex, "router.ex", "web/router.ex"}
    ] ++ get_html(opts[:api]) ++ get_confirm(opts[:confirm], opts[:api])

    if opts[:ecto] != false, do: Mix.Task.run "openmaize.gen.ectodb", []

    Mix.Openmaize.copy_files(srcdir, files, base: base,
     api: opts[:api] == true, confirm: opts[:confirm])

    Mix.shell.info """

    Please check the generated files. You might need to uncomment certain
    lines and / or change certain details, such as paths, user details.

    Before you use Openmaize, you need to configure Openmaize.
    See the documentation for Openmaize.Config for details.
    """
  end

  defp get_html(true), do: []
  defp get_html(_) do
    [{:eex, "authorize.ex", "web/controllers/authorize.ex"},
     {:text, "session_new.html.eex", "web/templates/session/new.html.eex"},
     {:text, "user_edit.html.eex", "web/templates/user/edit.html.eex"},
     {:text, "user_form.html.eex", "web/templates/user/form.html.eex"},
     {:text, "user_index.html.eex", "web/templates/user/index.html.eex"},
     {:text, "user_new.html.eex", "web/templates/user/new.html.eex"},
     {:text, "user_show.html.eex", "web/templates/user/show.html.eex"},
   ]
  end

  defp get_confirm(true, true) do
    [{:eex, "password_reset_controller.ex", "web/controllers/password_reset_controller.ex"},
     {:eex, "password_reset_controller_test.exs", "test/controllers/password_reset_controller_test.exs"},
     {:eex, "password_reset_view.ex", "web/views/password_reset_view.ex"}]
  end
  defp get_confirm(true, _) do
     [{:text, "password_reset_new.html.eex", "web/templates/password_reset/new.html.eex"},
     {:text, "password_reset_edit.html.eex", "web/templates/password_reset/edit.html.eex"}] ++
    get_confirm(true, true)
  end
  defp get_confirm(_, _), do: []

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)
end
