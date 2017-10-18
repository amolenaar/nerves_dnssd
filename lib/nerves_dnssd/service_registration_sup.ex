defmodule Nerves.Dnssd.ServiceRegistrationSup do
  use Supervisor

  @name __MODULE__

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  def register(name, protocol, port, txts \\ []) do
    Supervisor.start_child(@name, [name, protocol, port, txts])
  end

  def init([]) do
    SystemRegistry.TermStorage.persist [:config, :dnssd]
    Supervisor.init([Nerves.Dnssd.ServiceRegistration], strategy: :simple_one_for_one)
  end
end
