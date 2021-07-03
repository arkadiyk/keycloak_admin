defmodule KeycloakAdmin.Client do
  @moduledoc """
  Communications with Keycloak.
  """

  alias KeycloakAdmin.AsyncError
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

  def delete_user(token, base_url, realm, id) do
    :delete
    |> Finch.build("#{api_url(base_url, realm)}/users/#{URI.encode(id)}", [
      {"Authorization", "bearer #{token}"}
    ])
    |> Finch.request(KcFinch)
    |> parse_post_result(:delete_user, %{id: id})
  end

  defp parse_response({:ok, %Response{body: body}}) do
    Jason.decode(body)
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

    cond do
      status in [200, 201, 204] ->
        {:ok, body}

      content_type == "application/json" ->
        {:error, %AsyncError{op: op, input: input, status: status, error: Jason.decode!(body)}}

      true ->
        {:error, %AsyncError{op: op, input: input, status: status, error: body}}
    end
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
