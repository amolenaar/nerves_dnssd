defmodule Nerves.Dnssd.ServiceRegistration do
  @moduledoc """
  Ensure a service name survives an application restart.

  For example: I have 2 services on
  my network, both competing for a service name "Foo Service". The first service to
  be available on the network is claiming this name, hence the service that starts
  second will be named "Foo Service (2)". For the second service we need to persist
  this name, so that when the service starts up again it will advertise itself as
  "Foo Service (2)" (even if the first service is no longer available on the network).

  To achieve this, we apply a simple name mapping: if a name is registered for and
  the service knows internally it has been using another name in the past, it will
  use the name used before.

  Note that this module only handles the simple case where we want to register a
  `{name, protocol, port}` tuple on a `.local` domain using the current host name.

  See also: https://tools.ietf.org/html/rfc6762#section-9
  """
  use GenServer

  require Logger

  def start_link([], name, protocol, port, txt) do
    GenServer.start_link(__MODULE__, [name, protocol, port, txt])
  end

  # Server callbacks

  def init([name, protocol, port, txt]) do
    {:ok, ref} = :dnssd.register(service_name(name, protocol), protocol, port, txt)
    {:ok, {ref, name}}
  end

  def handle_info({:dnssd, ref, {:register, :add, {registered_name, protocol, domain}}}, {ref, name}=state) do
    Logger.info "Registered service '#{registered_name}' for #{protocol}#{domain}"
    update_name name, protocol, registered_name
    {:noreply, state}
  end

  def handle_info({:dnssd, ref, {:register, :remove, {registered_name, protocol, domain}}}, {ref, _name}=state) do
    Logger.info "Deregistered service '#{registered_name}' for #{protocol}#{domain}"
    {:stop, :normal, state}
  end

  def handle_info(info, state) do
    Logger.warn "Unexpected message: #{inspect info}; state: #{inspect state}"
    {:noreply, state}
  end

  defp service_name(name, protocol) do
    key = {name, protocol}
    case SystemRegistry.match(%{config: %{dnssd: %{service: %{key => :_}}}}) do
      %{config: %{dnssd: %{service: %{^key => alt_name}}}} -> alt_name
      _ -> name
    end
  end

  defp update_name(name, protocol, new_name) do
    SystemRegistry.update [:config, :dnssd, :service, {name, protocol}], new_name
  end
end
