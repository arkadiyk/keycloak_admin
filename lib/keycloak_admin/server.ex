defmodule KeycloakAdmin.Server do
  @moduledoc """
  Documentation for `KeycloakAdmin`.
  """

  use GenServer
  alias KeycloakAdmin.Client

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
         realm: KeycloakAdmin.Application.fetch_config(:realm),
         base_url: KeycloakAdmin.Application.fetch_config(:base_url),
         client_name: KeycloakAdmin.Application.fetch_config(:client_name),
         client_secret: KeycloakAdmin.Application.fetch_config(:client_secret),
         max_concurrency: KeycloakAdmin.Application.fetch_config(:max_concurrency, 25)
       }
     }}
  end

  @impl true
  def handle_call(:login, _from, state) do
    access_token = setup_token(state)
    {:reply, :ok, Map.put(state, :token, access_token)}
  end

  @impl true
  def handle_call(:get_errors, _from, state) do
    {:reply, state.errors, state}
  end

  @impl true
  def handle_call(:get_token, _from, state) do
    {:reply, state.token, state}
  end

  @impl true
  def handle_call(:get_config, _from, state) do
    {:reply, state.config, state}
  end

  @impl true
  def handle_info(:refresh_token, state) do
    access_token = setup_token(state)
    {:noreply, Map.put(state, :token, access_token)}
  end

  defp setup_token(state) do
    %{"access_token" => access_token, "expires_in" => expires_in} = login(state.config)
    Process.send_after(self(), :refresh_token, (expires_in - 10) * 1000)
    access_token
  end

  defp login(%{base_url: base_url, client_name: client_name, client_secret: client_secret}) do
    {:ok, token} = Client.obtain_token(base_url, client_name, client_secret)
    token
  end
end
