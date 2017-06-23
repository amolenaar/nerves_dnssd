defmodule Nerves.Dnssd do
  @moduledoc """
  The `Nerves.Dnssd` application.

  The application will (in an embedded setting) manage the mDNS daemon.
  Via the config option `:daemon_restart` the start behaviour can be managed.
  Default is `:permanent`. On a desktop there may already be a daemon running,
  so a failed start should just be ignored.

  Once the application is started services can be registered and browsed via
  the [Erlang API](readme.html#example-use).
  """

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    :ok = :dnssd_drv.load()

    daemon_restart = Application.get_env(:nerves_dnssd, :daemon_restart, :permanent)

    children = [
      worker(Nerves.Dnssd.Daemon, [], restart: daemon_restart),
      worker(:dnssd_server, [], restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Nerves.Dnssd.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def stop(_state) do
    :ok = :dnssd_drv.unload()
  end

end
