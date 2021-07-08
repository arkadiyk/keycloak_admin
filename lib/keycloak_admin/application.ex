defmodule KeycloakAdmin.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch,
       name: KcFinch,
       pools: %{
         default: [size: max_concurrency() + 5]
       }},
      KeycloakAdmin.Server,
      {Task.Supervisor, name: KeycloakAdmin.TaskSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KeycloakAdmin.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def fetch_config(key, default \\ nil) do
    case Application.fetch_env(:keycloak_admin, key) do
      {:ok, config_value} ->
        config_value

      :error ->
        if is_nil(default), do: raise("required `#{key}` configuration is not defined")
        default
    end
  end

  def max_concurrency do
    :max_concurrency |> fetch_config("25") |> String.to_integer()
  end
end
