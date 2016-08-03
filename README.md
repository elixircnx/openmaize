# Openmaize [![Build Status](https://travis-ci.org/riverrun/openmaize.svg?branch=master)](https://travis-ci.org/riverrun/openmaize) [![Deps Status](https://beta.hexfaktor.org/badge/all/github/riverrun/openmaize.svg)](https://beta.hexfaktor.org/github/riverrun/openmaize)

Authentication library for Plug-based applications in Elixir

## Upgrading to the newest version

There have been a few changes in the newest versions, 1.0.0.
Please check the `UPGRADE_1.1.md` guide in this directory for details.

## Goals

Openmaize is an authentication library that aims to be:

* secure
* lightweight
* easy to use
* well documented

It should work with any application that uses Plug, but it has only been
tested with the Phoenix Web Framework.

## Installation

1. Add openmaize to your `mix.exs` dependencies

  ```elixir
  defp deps do
    [{:openmaize, "~> 1.1"}]
  end
  ```

2. List `:openmaize` as an application dependency

  ```elixir
  def application do
    [applications: [:logger, :openmaize]]
  end
  ```

3. Run `mix do deps.get, compile`

## Use

Before you use Openmaize, you need to make sure that you have a module
that implements the Openmaize.Database behaviour. If you are using Ecto,
you can generate the necessary files by running the following command:

    mix openmaize.gen.ectodb

To generate modules to handle authorization, and optionally email confirmation,
run the following command:

    mix openmaize.gen.phoenixauth

You then need to configure Openmaize. For more information, see the documentation
for the Openmaize.Config module.

## Migrating from [Devise](https://github.com/plataformatec/devise)

Follow the above instructions for generating database and authorization
modules, and then add the following lines to the config file:

    config :openmaize,
      hash_name: :encrypted_password

Some of the functions in the Authorize module depend on a `role` being
set for each user. If you are not using roles, you will need to edit
these functions before use.

## Openmaize plugs

  * Authentication
    * Openmaize.Authenticate - plug to authenticate users, using sessions.
    * Openmaize.Login - plug to handle login POST requests.
    * Openmaize.OnetimePass - plug to handle one-time password POST requests.
    * Openmaize.Remember - plug to check for a `remember me` cookie.
  * Email confirmation and password resetting
    * Openmaize.ConfirmEmail - verify the token that was sent to the user by email.
    * Openmaize.ResetPassword - verify the token that was sent to the user by email,
    but this time so that the user's password can be reset.

See the relevant module documentation for more details.

## Using with Phoenix

There is an example of Openmaize being used with Phoenix at
[Openmaize-phoenix](https://github.com/riverrun/openmaize-phoenix).

### License

BSD
