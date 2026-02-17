defmodule Splendor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SplendorWeb.Telemetry,
      Splendor.Repo,
      {DNSCluster, query: Application.get_env(:splendor, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Splendor.PubSub},
      # Start a worker by calling: Splendor.Worker.start_link(arg)
      # {Splendor.Worker, arg},
      # Start to serve requests, typically the last entry
      SplendorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Splendor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SplendorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
