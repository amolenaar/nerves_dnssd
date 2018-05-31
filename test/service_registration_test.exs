defmodule ServiceRegistrationTest do
  use ExUnit.Case, async: true

  @protocol "_exunit._tcp"
  # Bonjour adds a dot suffix to the protocol name
  @dnsprotocol @protocol <> "."
  @port 80

  test "register with new name" do
    Nerves.Dnssd.register "Service name", @protocol, @port

    {:ok, ref} = :dnssd.browse @protocol
    assert_receive {:dnssd, ^ref, {:browse, :add, {"Service name", @dnsprotocol, "local."}}}, 5000
    :dnssd.stop ref
  end

  test "register twice" do
    # Setup, ensure a name is present
    :dnssd.register "Double name", @protocol, @port

    {:ok, ref} = :dnssd.browse @protocol
    assert_receive {:dnssd, ^ref, {:browse, :add, {"Double name", @dnsprotocol, "local."}}}, 5000

    # Create our "double" name
    Nerves.Dnssd.register "Double name", @protocol, @port + 1

    assert_receive {:dnssd, ^ref, {:browse, :add, {"Double name (2)", @dnsprotocol, "local."}}}, 5000
    :dnssd.stop ref

    # Check registration
    key = {"Double name", @protocol}
    reg = SystemRegistry.match(%{config: %{dnssd: %{key => :_}}})
    assert %{config: %{dnssd: %{^key => "Double name (2)"}}} = reg
  end

  test "name is registered in system registry" do
    Nerves.Dnssd.register "In System_registry", @protocol, @port

    {:ok, ref} = :dnssd.browse @protocol
    assert_receive {:dnssd, ^ref, {:browse, :add, {"In System_registry", @dnsprotocol, "local."}}}, 5000
    :dnssd.stop ref

    key = {"In System_registry", @protocol}
    reg = SystemRegistry.match(%{config: %{dnssd: %{key => "In System_registry"}}})
    assert %{config: %{dnssd: %{^key => "In System_registry"}}} = reg
  end

  test "register with name from system registry" do
    SystemRegistry.update [:config, :dnssd, {"Sysreg name", @protocol}], "Another name"

    :timer.sleep(10)

    Nerves.Dnssd.register "Sysreg name", @protocol, @port

    {:ok, ref} = :dnssd.browse @protocol
    assert_receive {:dnssd, ^ref, {:browse, :add, {"Another name", @dnsprotocol, "local."}}}, 5000
    :dnssd.stop ref
  end

end
