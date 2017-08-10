defmodule NervesDnssdDemo.Application do
  use Application

  @interface :eth0

  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do

    if Application.get_env(:nerves_dnssd_demo, :networking, true) do
      Nerves.Networking.setup @interface
    end

    announce_node()

    {:ok, self()}
  end

  def announce_node do
    Logger.info "Registering node as #{:erlang.node}"
    {:ok, local_name, local_ip} = :dnssd_epmd_stub.local_port_please()
    :dnssd.register(local_name, "_epmd._tcp", local_ip, [{"node", :erlang.node}])
  end

end
