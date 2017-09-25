defmodule Nerves.Dnssd do
  @moduledoc """
  The `Nerves.Dnssd` application.

  The application will (in an embedded setting) manage the mDNS daemon.
  Via the config option `:daemon_restart` the start behaviour can be managed.
  Default is `:permanent`. On a desktop there may already be a daemon running,
  so a failed start should just be ignored, by either setting this property
  to `:temporary` (try once and ignore failure) or `:ignore`. `:transient` may
  also be set if desired, although `:permanent` is probably prefered in such
  circumstances.

  Once the application is started services can be registered and browsed via
  the [Erlang API](readme.html#example-use).
  """

  import Supervisor.Spec, only: [worker: 3]

  def start(_type, _args) do

    :ok = :dnssd_drv.load()

    children = daemon_worker() ++ [
      worker(:dnssd_server, [], restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Nerves.Dnssd.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def daemon_worker do
    case Application.get_env(:nerves_dnssd, :daemon_restart, :permanent) do
      :ignore ->
         []
      r when r in [:permanent, :transient, :temporary] ->
        [worker(Nerves.Dnssd.Daemon, [], restart: r)]
      other ->
        raise "Invalid Nerves Dnssd daemon start policy #{other}, should be one of :ignore, :permanent, :transient or :temporary."
    end
  end

  def stop(_state) do
    :ok = :dnssd_drv.unload()
  end

end
