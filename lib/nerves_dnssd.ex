defmodule Nerves.Dnssd do
  @moduledoc """
  The `Nerves.Dnssd` application.

  The application will (in an embedded setting) manage the mDNS daemon.
  Once the application is started services can be registered and browsed via
  the [Erlang API](readme.html#example-use).

  In the most basic situation, where one wants to simply register a service
  on the network, calling

  ```elixir
  iex> {:ok, pid} = Nerves.Dnssd.register("Fancy service name", "_http._tcp", 8080)
  iex> is_pid(pid)
  true
  ```

  is sufficient to register a HTTP service listening on port 8080. In case there is
  already a service named "Fancy service name" a new name will be determined by
  using a follow-up number and that name will be registered, so that after a restart
  the service will advertise itself with the same name.

  If you want to do more, you'll have to use the [_dnssd_ interface](dnssd.html).
  """

  import Supervisor.Spec, only: [supervisor: 3, worker: 3]

  def start(_type, _args) do

    :ok = :dnssd_drv.load()

    children = daemon_worker() ++ [
      worker(:dnssd_server, [], restart: :permanent),
      supervisor(Nerves.Dnssd.ServiceRegistrationSup, [], restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Nerves.Dnssd.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def stop(_state) do
    :ok = :dnssd_drv.unload()
  end

  defdelegate register(name, protocol, port, txts \\ []), to: Nerves.Dnssd.ServiceRegistrationSup

  defp daemon_worker do
    case Application.get_env(:nerves_dnssd, :daemon_restart, :permanent) do
      :ignore ->
         []
      r when r in [:permanent, :transient, :temporary] ->
        [worker(Nerves.Dnssd.Daemon, [], restart: r)]
      other ->
        raise "Invalid Nerves Dnssd daemon start policy #{other}, should be one of :ignore, :permanent, :transient or :temporary."
    end
  end

end
