defmodule Nerves.Dnssd.ServiceRegistrationSup do
  @moduledoc """
  Supervisor for service registrations.
  """

  use DynamicSupervisor

  @name __MODULE__

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: @name)
  end

  @doc """
  Register a new services. The service remains registered as long
  as the registration process remains active.

  Normally this would be the whole lifetime of the application.
  """
  @spec register(String.t, String.t, non_neg_integer, [String.t]) :: {:ok, pid} | {:error, String.t}
  def register(name, protocol, port, txts \\ []) do
    DynamicSupervisor.start_child(
      @name,
      {Nerves.Dnssd.ServiceRegistration, {name, protocol, port, txts}}
    )
  end

  def init(_arg) do
    SystemRegistry.TermStorage.persist [:config, :dnssd]
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
