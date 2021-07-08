defmodule KeycloakAdmin.Client do
  @moduledoc """
  Communications with Keycloak.
  """

  alias KeycloakAdmin.KcResponse
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
        "#{api_url(base_url, realm)}/users?#{get_params(query_params)}",
        [{"Authorization", "bearer #{token}"}]
      )
      |> Finch.request(KcFinch)
      |> parse_response()

    {:ok, result}
  end

  def create_user(token, base_url, realm, user_data) do
    :post
    |> Finch.build(
      "#{api_url(base_url, realm)}/users",
      [{"Authorization", "bearer #{token}"}, {"Content-Type", "application/json"}],
      post_params(user_data)
    )
    |> Finch.request(KcFinch)
    |> parse_post_result(:create_user, user_data)
  end

  def delete_user(token, base_url, realm, user) do
    id = user.id
    :delete
    |> Finch.build("#{api_url(base_url, realm)}/users/#{id}", [
      {"Authorization", "bearer #{token}"}
    ])
    |> Finch.request(KcFinch)
    |> parse_post_result(:delete_user, user)
  end

  defp parse_response({:ok, %Response{body: body}}) do
    Jason.decode(body, keys: :atoms)
  end

  defp parse_response({:error, error}) do
    Logger.error("ERROR: #{inspect(error)}")
    {:error, "ERROR: #{inspect(error)}"}
  end

  defp parse_post_result(
         {:ok, %Response{body: body, status: status, headers: headers}},
         op,
         input
       ) do
    content_type = headers |> Enum.into(%{}) |> Map.get("content-type")
    result = if status in [200, 201, 204], do: :ok, else: :error

    response =
      if content_type == "application/json" do
        Jason.decode!(body, keys: :atoms)
      else
        body
      end

    {result, %KcResponse{op: op, input: input, status: status, response: response}}
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

  defp get_params(struct) when is_map(struct) do
    struct
    |> Map.from_struct()
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> URI.encode_query()
  end

  defp post_params(struct) when is_map(struct) do
    struct
    |> Map.from_struct()
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
    |> Jason.encode!()
  end
end
