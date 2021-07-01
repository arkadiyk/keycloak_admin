defmodule KeycloakAdmin do
  @moduledoc """
  Documentation for `KeycloakAdmin`.
  """
  alias KeycloakAdmin.Server
  alias KeycloakAdmin.Representations.{User, UserQuery}

  def login() do
    GenServer.cast(Server, :login)
  end

  def get_users() do
    GenServer.call(Server, {:get_users, %UserQuery{}})
  end

  def get_users(%UserQuery{} = query) do
    GenServer.call(Server, {:get_users, query})
  end

  @doc """
  send a request to create a user and returns without waiting for a result.
  If any errors happened they will be stored and can be retrieved using `KeycloakAdmin.get_errors()`
  """
  def async_create_user(%User{} = user_object) do
    GenServer.cast(Server, {:create_user, user_object})
  end

  def get_errors() do
    GenServer.call(Server, :get_errors)
  end
end
