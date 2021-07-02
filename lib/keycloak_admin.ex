defmodule KeycloakAdmin do
  @moduledoc """
  Documentation for `KeycloakAdmin`.
  """
  alias KeycloakAdmin.{Server, Client, AsyncError}
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

  def batch_create_users(users) when is_list(users) do
    stream =
      Task.async_stream(users, fn user -> create_user(user) end,
        timeout: 60_000,
        max_concurrency: KeycloakAdmin.Application.fetch_config(:max_concurrency, 25)
      )

    Enum.to_list(stream)
  end

  def batch_delete_users(%UserQuery{} = query, safety_limit \\ 1) do
    {:ok, users} = get_users(query)

    if length(users) > safety_limit do
      error = %AsyncError{
        op: :delete_users,
        input: query,
        error:
          "Number of users (#{length(users)}) to delete exceeds safety limit of #{safety_limit}"
      }

      [error]
    else
      stream =
        Task.async_stream(users, fn %{"id" => user_id} -> delete_user(user_id) end,
          timeout: 60_000,
          max_concurrency: KeycloakAdmin.Application.fetch_config(:max_concurrency, 25)
        )

      Enum.to_list(stream)
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
end
