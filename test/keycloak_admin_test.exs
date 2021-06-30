defmodule KeycloakAdminTest do
  use ExUnit.Case
  doctest KeycloakAdmin

  test "greets the world" do
    assert KeycloakAdmin.hello() == :world
  end
end
