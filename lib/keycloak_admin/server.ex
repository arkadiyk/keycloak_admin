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
    send(self(), :refresh_token)
    {:noreply, state}
  end

  @impl true
  def handle_info(:refresh_token, state) do
    IO.inspect(state, label: "**** refreshing")
    %{"access_token" => access_token, "expires_in" => expires_in} = login(state.config)
    Process.send_after(self(), :refresh_token, (expires_in - 10) * 1000)
    {:noreply, Map.put(state, :token, access_token)}
  end

  @impl true
  def handle_call({:get_users, query}, _from, state) do
    %{base_url: base_url, realm: realm} = state.config
    users = Client.get_users(state.token, base_url, realm, get_params(query))
    {:reply, users, state}
  end

  defp login(%{base_url: base_url, client_name: client_name, client_secret: client_secret}) do
    {:ok, token} = Client.obtain_token(base_url, client_name, client_secret)
    token
  end

  defp config(config_key) do
    Application.fetch_env!(:keycloak_admin, config_key)
  end

  defp get_params(struct) when is_map(struct) do
    struct
    |> Map.from_struct()
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> URI.encode_query()
  end
end
