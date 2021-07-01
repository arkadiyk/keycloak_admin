defmodule KeycloakAdmin.Server do
  @moduledoc """
  Documentation for `KeycloakAdmin`.
  """

  alias KeycloakAdmin.{Client, AsyncError}
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  ## Callbacks

  @impl true
  def init(_) do
    {:ok,
     %{
       errors: [],
       config: %{
         realm: config(:realm),
         base_url: config(:base_url),
         client_name: config(:client_name),
         client_secret: config(:client_secret)
       }
     }}
  end

  @impl true
  def handle_cast(:login, state) do
    setup_token(state)
  end

  @impl true
  def handle_cast({:create_user, user_data}, %{token: token, config: config} = state) do
    %{base_url: base_url, realm: realm} = config

    case Client.create_user(token, base_url, realm, user_data) do
      {:ok, _status} -> {:noreply, state}
      {:error, error} -> {:noreply, Map.put(state, :errors, [error | state.errors])}
    end
  end

  @impl true
  def handle_cast({:delete_users, query, safety_limit}, %{token: token, config: config} = state) do
    %{base_url: base_url, realm: realm} = config
    {:ok, users} = Client.get_users(token, base_url, realm, query)

    if length(users) > safety_limit do
      error = %AsyncError{
        op: :delete_users,
        input: query,
        error:
          "Number of users (#{length(users)}) to delete exceeds safety limit of #{safety_limit}"
      }

      {:noreply, Map.put(state, :errors, [error | state.errors])}
    else
      for %{"id" => id} <- users, do: send(self(), {:delete_single_user, id})
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:refresh_token, state) do
    setup_token(state)
  end

  @impl true
  def handle_info({:delete_single_user, id}, %{token: token, config: config} = state) do
    %{base_url: base_url, realm: realm} = config

    case Client.delete_user(token, base_url, realm, id) do
      {:ok, _status} -> {:noreply, state}
      {:error, error} -> {:noreply, Map.put(state, :errors, [error | state.errors])}
    end
  end

  @impl true
  def handle_call({:get_users, query}, _from, %{token: token, config: config} = state) do
    %{base_url: base_url, realm: realm} = config
    {:ok, users} = Client.get_users(token, base_url, realm, query)
    {:reply, users, state}
  end

  @impl true
  def handle_call(:get_errors, _from, state) do
    {:reply, state.errors, state}
  end

  @impl true
  def handle_call(_, _from, state) do
    {:reply, {:error, "Please run KeycloakAdmin.login() before any other functions"}, state}
  end

  defp setup_token(state) do
    %{"access_token" => access_token, "expires_in" => expires_in} = login(state.config)
    Process.send_after(self(), :refresh_token, (expires_in - 10) * 1000)
    {:noreply, Map.put(state, :token, access_token)}
  end

  defp login(%{base_url: base_url, client_name: client_name, client_secret: client_secret}) do
    {:ok, token} = Client.obtain_token(base_url, client_name, client_secret)
    token
  end

  defp config(config_key) do
    Application.fetch_env!(:keycloak_admin, config_key)
  end
end
