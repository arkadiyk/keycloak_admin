defmodule KeycloakAdmin.AsyncError do
  defstruct [:op, :error, :input, :status]
end
