defmodule KeycloakAdmin do
  @moduledoc """
  Documentation for `KeycloakAdmin`.
  """
  alias KeycloakAdmin.{Server, Client, KcResponse}
  alias KeycloakAdmin.Representations.{User, UserQuery}

  def login() do
    GenServer.call(Server, :login)
  end

  def get_users() do
    get_users(%UserQuery{})
  end

  def get_users(%UserQuery{} = query) do
    token = get_token()
    %{base_url: base_url, realm: realm} = get_config()
    Client.get_users(token, base_url, realm, query)
  end

  def batch_create_users(users, options \\ []) when is_list(users) do
    callback = Keyword.get(options, :callback, & &1)

    users
    |> Task.async_stream(&create_user/1,
      timeout: 60_000,
      ordered: false,
      max_concurrency: get_config(:max_concurrency)
    )
    |> Stream.map(fn {:ok, res} -> res end)
    |> Stream.map(callback)
    |> Enum.to_list()
  end

  def batch_delete_users(userQueries, options \\ []) do
    callback = Keyword.get(options, :callback, & &1)

    userQueries
    |> Task.async_stream(
      fn userQuery ->
        {:ok, users} = get_users(userQuery)

        case check_limit(users, 1, userQuery) do
          :ok -> delete_user(List.first(users))
          error -> error
        end
      end,
      timeout: 60_000,
      ordered: false,
      max_concurrency: get_config(:max_concurrency)
    )
    |> Stream.map(fn {:ok, res} -> res end)
    |> Stream.map(callback)
    |> Enum.to_list()
  end

  def delete_users(%UserQuery{} = userQuery, options \\ []) do
    safety_limit = Keyword.get(options, :safety_limit, 1)
    callback = Keyword.get(options, :callback, & &1)
    {:ok, users} = get_users(userQuery)

    case check_limit(users, safety_limit, userQuery) do
      :ok ->
        users
        |> Task.async_stream(
          &delete_user/1,
          timeout: 60_000,
          ordered: false,
          max_concurrency: get_config(:max_concurrency)
        )
        |> Stream.map(fn {:ok, res} -> res end)
        |> Stream.map(callback)
        |> Enum.to_list()

      error ->
        error
    end
  end

  def create_user(%User{} = user_data) do
    token = get_token()
    %{base_url: base_url, realm: realm} = get_config()
    Client.create_user(token, base_url, realm, user_data)
  end

  def delete_user(user) do
    token = get_token()
    %{base_url: base_url, realm: realm} = get_config()
    Client.delete_user(token, base_url, realm, user)
  end

  defp check_limit(users, limit, query) do
    cond do
      Enum.empty?(users) ->
        {:error,
         %KcResponse{
           op: :delete_users,
           input: query,
           response: "User is not in the Keycloak"
         }}

      length(users) > limit ->
        {:error,
         %KcResponse{
           op: :delete_users,
           input: query,
           response:
             "Number of users (#{length(users)}) to delete exceeds safety limit of #{limit}"
         }}

      true ->
        :ok
    end
  end

  defp get_token() do
    GenServer.call(Server, :get_token)
  end

  defp get_config() do
    GenServer.call(Server, :get_config)
  end

  defp get_config(config_key) do
    get_config() |> Map.get(config_key)
  end
end
