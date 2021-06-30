defmodule KeycloakAdmin.Server do
  @moduledoc """
  Documentation for `KeycloakAdmin`.
  """

  alias KeycloakAdmin.Client
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  ## Callbacks

  @impl true
  def init(_) do
    {:ok,
     %{
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
    %{
      base_url: base_url,
      client_name: client_name,
      client_secret: client_secret
    } = state.config
    {:ok, token} = Client.obtain_token(base_url, client_name, client_secret)
    IO.inspect(token, label: "-------")
    {:noreply, Map.put(state, :token, token)}
  end

  @impl true
  def handle_call(:get_users, _from, state) do
    %{ base_url: base_url, realm: realm } = state.config
    users = Client.get_users(state.token, base_url, realm)
    {:reply, users, state}
  end

  defp config(config_key) do
    Application.fetch_env!(:keycloak_admin, config_key)
  end
end
