defmodule Nerves.Dnssd do
  @moduledoc """
  Start the mdns daemon as a port process.
  """

  @doc """
  """
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    :ok = :dnssd_drv.load()

    children = [
      #worker(Nerves.Dnssd.Daemon, []), # make :transient/:permanent dependent on platform
      supervisor(:dnssd_sup, [])
    ]

    opts = [strategy: :one_for_one, name: Nerves.Dnssd.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def stop(_state) do
    :ok = :dnssd_drv.unload()
  end

end
