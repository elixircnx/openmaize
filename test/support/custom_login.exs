defmodule Openmaize.CustomLogin do
  use Openmaize.Login.Base

  def unpack_params(%{"phone" => phone, "password" => password}) do
    {:phone, phone, password}
  end
  def unpack_params(_), do: nil
end
defmodule Openmaize.CustomLogin.Phonename do
  use Openmaize.Login.Base

  def unpack_params(%{"phone" => phone, "password" => password}) do
    {Regex.match?(~r/^[0-9]+$/, phone) and :phone || :username, phone, password}
  end
  def unpack_params(_), do: nil
end
