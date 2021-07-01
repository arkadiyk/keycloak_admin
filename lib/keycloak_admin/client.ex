defmodule KeycloakAdmin.Client do
  @moduledoc """
  Communications with Keycloak.
  """

  alias Finch.Response

  @doc """
  obtain token
  """
  def obtain_token(base_url, client_name, client_secret) do
    token =
      :post
      |> Finch.build(
        token_url(base_url),
        [{"Content-Type", "application/x-www-form-urlencoded"}],
        token_request_body(client_name, client_secret)
      )
      |> Finch.request(KcFinch)
      |> parse_response()

    {:ok, token}
  end

  def get_users(token, base_url, realm, query_params) do
    IO.inspect("#{api_url(base_url, realm)}/users?#{query_params}")
    result =
      :get
      |> Finch.build(
        "#{api_url(base_url, realm)}/users?#{query_params}",
        [{"Authorization", "bearer #{token}"}]
      )
      |> Finch.request(KcFinch)
      |> parse_response()

    {:ok, result}
  end

  defp parse_response({:ok, %Response{body: body}}) do
    Jason.decode!(body)
  end

  defp token_request_body(client_name, client_secret) do
    URI.encode_query(%{
      "grant_type" => "client_credentials",
      "client_id" => client_name,
      "client_secret" => client_secret
    })
  end

  defp token_url(base_url) do
    "#{base_url}/auth/realms/master/protocol/openid-connect/token"
  end

  defp api_url(base_url, realm) do
    "#{base_url}/auth/admin/realms/#{realm}"
  end
end
