# KeycloakAdmin

Very light Elixir wrapper around [Keycloak REST API](https://www.keycloak.org/docs-api/14.0/rest-api/index.html)
Can be used for ETL jobs or Admin UI without exposing whole Keycloak Admin console.

If it used to build an Admin UI it highly recommended to authorize user either against the same Keycloak or any other mechanism.

## Configuration

In `config/runtime.exs` :

```elixir
config :keycloak_admin,
  realm: "examplerealm",
  base_url: "https://id.example.com",
  client_name: "example-client-name",
  client_secret: "secret"
```

### Keycloak configuration
- In *Master Realm* create / setup a client with *Access Type: confidential*. 
- On the *Credential* tab select *Client Authenticator: Client id and Secret*  

## Installation

```elixir
def deps do
  [
    {:keycloak_admin, git: "https://github.com/arkadiyk/keycloak_admin.git", tag: "0.0.2"}
  ]
end
```
