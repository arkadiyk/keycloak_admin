defmodule KeycloakAdmin.MixProject do
  use Mix.Project

  def project do
    [
      app: :keycloak_admin,
      version: "0.0.1",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {KeycloakAdmin.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.8.0"},
      {:jason, "~> 1.2"}
    ]
  end
end
