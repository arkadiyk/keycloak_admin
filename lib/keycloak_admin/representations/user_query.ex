defmodule KeycloakAdmin.Representations.UserQuery do
  @moduledoc """
    Keycloak API User Query Representation.
    https://www.keycloak.org/docs-api/14.0/rest-api/index.html#_users_resource
  """

  defstruct [
    :briefRepresentation,
    :email,
    :emailVerified,
    :enabled,
    :exact,
    :first,
    :firstName,
    :idpAlias,
    :idpUserId,
    :lastName,
    :max,
    :search,
    :username
  ]
end
