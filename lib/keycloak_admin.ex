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

  def batch_delete_users(%UserQuery{} = query, options \\ []) do
    safety_limit = Keyword.get(options, :safety_limit, 1)
    callback = Keyword.get(options, :callback, & &1)
    {:ok, users} = get_users(query)

    if length(users) > safety_limit do
      error = %KcResponse{
        op: :delete_users,
        input: query,
        response:
          "Number of users (#{length(users)}) to delete exceeds safety limit of #{safety_limit}"
      }

      [{:error, error}]
    else
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
    end
  end

  def create_user(%User{} = user_data) do
    token = get_token()
    %{base_url: base_url, realm: realm} = get_config()
    Client.create_user(token, base_url, realm, user_data)
  end

  def delete_user(id) do
    token = get_token()
    %{base_url: base_url, realm: realm} = get_config()
    Client.delete_user(token, base_url, realm, id)
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
