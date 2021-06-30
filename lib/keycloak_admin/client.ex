defmodule KeycloakAdmin.Client do
  @moduledoc """
  Communications with Keycloak.
  """

  alias Finch.Response

  @doc """
  obtain token
  """
  def obtain_token do
    :post
    |> Finch.build(
      token_url(),
      [{"Content-Type", "application/x-www-form-urlencoded"}],
      token_request_body()
    )
    |> Finch.request(KcFinch)
    |> parse_token()
  end

  def parse_token({:ok, %Response{body: body}}) do
    token =
      body
      |> Jason.decode!()
      |> Map.get("access_token")

    {:ok, token}
  end

  def token_request_body do
    URI.encode_query(%{
      "grant_type" => "client_credentials",
      "client_id" => keycloak(:client_name),
      "client_secret" => keycloak(:client_secret)
    })
  end

  def keycloak(config_key) do
    Application.fetch_env!(:keycloak_admin, config_key)
  end

  def token_url do
    "#{keycloak(:base_url)}/auth/realms/master/protocol/openid-connect/token"
  end
end
