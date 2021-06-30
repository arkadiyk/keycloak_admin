defmodule KeycloakAdmin do
  @moduledoc """
  Documentation for `KeycloakAdmin`.
  """
  alias KeycloakAdmin.Server

  def login() do
    GenServer.cast(Server, :login)
  end

  def get_users() do
    GenServer.call(Server, :get_users)
  end

  def hello do
    :world
  end
end
