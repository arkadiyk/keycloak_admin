defmodule KeycloakAdmin do
  @moduledoc """
  Documentation for `KeycloakAdmin`.
  """
  alias KeycloakAdmin.Server
  alias KeycloakAdmin.Representations.UserQuery

  def login() do
    GenServer.cast(Server, :login)
  end

  def get_users() do
    GenServer.call(Server, {:get_users, %UserQuery{}})
  end

  def get_users(%UserQuery{} = query) do
    GenServer.call(Server, {:get_users, query})
  end
end
