defmodule ServiceRegistrationTest do
  use ExUnit.Case, async: true

  @protocol "_exunit._tcp."
  @port 80

  test "register with new name" do
    Nerves.Dnssd.register "Service name", @protocol, @port

    {:ok, ref} = :dnssd.browse @protocol
    assert_receive {:dnssd, ^ref, {:browse, :add, {"Service name", @protocol, "local."}}}, 5000
    :dnssd.stop ref
  end

  test "register twice" do
    # Setup, ensure a name is present
    :dnssd.register "Double name", @protocol, @port

    {:ok, ref} = :dnssd.browse @protocol
    assert_receive {:dnssd, ^ref, {:browse, :add, {"Double name", @protocol, "local."}}}, 5000

    # Create our "double" name
    Nerves.Dnssd.register "Double name", @protocol, @port + 1

    assert_receive {:dnssd, ^ref, {:browse, :add, {"Double name (2)", @protocol, "local."}}}, 5000
    :dnssd.stop ref

    # Check registration
    key = {"Double name", @protocol}
    reg = SystemRegistry.match(%{config: %{dnssd: %{service: %{key => :_}}}})
    assert %{config: %{dnssd: %{service: %{^key => "Double name (2)"}}}} = reg
  end

  test "name is registered in system registry" do
    Nerves.Dnssd.register "In System_registry", @protocol, @port

    {:ok, ref} = :dnssd.browse @protocol
    assert_receive {:dnssd, ^ref, {:browse, :add, {"In System_registry", @protocol, "local."}}}, 5000
    :dnssd.stop ref

    key = {"In System_registry", @protocol}
    reg = SystemRegistry.match(%{config: %{dnssd: %{service: %{key => "In System_registry"}}}})
    assert %{config: %{dnssd: %{service: %{^key => "In System_registry"}}}} = reg
  end

  test "register with name from system registry" do
    SystemRegistry.update [:config, :dnssd, :service, {"Sysreg name", @protocol}], "Another name"

    Nerves.Dnssd.register "Sysreg name", @protocol, @port

    {:ok, ref} = :dnssd.browse @protocol
    assert_receive {:dnssd, ^ref, {:browse, :add, {"Another name", @protocol, "local."}}}, 5000
    :dnssd.stop ref
  end

end
