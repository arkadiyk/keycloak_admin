defmodule KeycloakAdmin.Client do
  @moduledoc """
  Communications with Keycloak.
  """

  alias Finch.Response
  require Logger

  @doc """
  obtain token
  """
  def obtain_token(base_url, client_name, client_secret) do
    {:ok, token} =
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
    {:ok, result} =
      :get
      |> Finch.build(
        "#{api_url(base_url, realm)}/users?#{query_params}",
        [{"Authorization", "bearer #{token}"}]
      )
      |> Finch.request(KcFinch)
      |> parse_response()

    {:ok, result}
  end

  def create_user(token, base_url, realm, user_json) do
    {:ok, result} =
      :post
      |> Finch.build(
        "#{api_url(base_url, realm)}/users",
        [{"Authorization", "bearer #{token}"}, {"Content-Type", "application/json"}],
        user_json
      )
      |> Finch.request(KcFinch)

    {:ok, result.status}
  end

  defp parse_response({:ok, %Response{body: body}}) do
    Jason.decode(body)
  end

  defp parse_response({:error, error}) do
    Logger.error("ERROR: #{inspect(error)}")
    {:error, "ERROR: #{inspect(error)}"}
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
