defmodule Nerves.Dnssd.ServiceRegistrationSup do
  @moduledoc """
  Supervisor for service registrations.
  """

  use Supervisor

  @name __MODULE__

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  @doc """
  Register a new services. The service remains registered as long
  as the registration process remains active.

  Normally this would be the whole lifetime of the application.
  """
  @spec register(String.t, String.t, non_neg_integer, [String.t]) :: {:ok, pid} | {:error, String.t}
  def register(name, protocol, port, txts \\ []) do
    Supervisor.start_child(@name, [name, protocol, port, txts])
  end

  def init([]) do
    SystemRegistry.TermStorage.persist [:config, :dnssd]
    Supervisor.init([Nerves.Dnssd.ServiceRegistration], strategy: :simple_one_for_one)
  end
end
