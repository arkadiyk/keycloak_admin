defmodule KeycloakAdmin.Representations.User do
  @moduledoc """
    Keycloak API UserRepresentation.
    https://www.keycloak.org/docs-api/14.0/rest-api/index.html#_userrepresentation
  """

  defstruct [
    :access,
    :attributes,
    :clientConsents,
    :clientRoles,
    :createdTimestamp,
    :credentials,
    :disableableCredentialTypes,
    :email,
    :emailVerified,
    :enabled,
    :federatedIdentities,
    :federationLink,
    :firstName,
    :groups,
    :id,
    :lastName,
    :notBefore,
    :origin,
    :realmRoles,
    :requiredActions,
    :self,
    :serviceAccountClientId,
    :totp,
    :username
  ]
end
