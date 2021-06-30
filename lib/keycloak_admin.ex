defmodule KeycloakAdmin do
  @moduledoc """
  Documentation for `KeycloakAdmin`.
  """
  alias KeycloakAdmin.Server

  def login() do
    GenServer.cast(Server, :login)
  end

  def hello do
    :world
  end
end
