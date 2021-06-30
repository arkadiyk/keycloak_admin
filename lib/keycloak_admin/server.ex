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
    {:ok, %{}}
  end

  @impl true
  def handle_cast(:login, state) do
    {:ok, token} = Client.obtain_token()
    IO.inspect(token, label: "-------")
    {:noreply, Map.put(state, :token, token)}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end


  @doc """
  Hello world.

  ## Examples

      iex> KeycloakAdmin.hello()
      :world

  """
  def hello do
    :world
  end
end
