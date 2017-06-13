defmodule NervesDnssdTest do
  use ExUnit.Case
  doctest Nerves.Dnssd

  test "the truth" do
    {:ok, pid} = Nerves.Dnssd.Daemon.start_link()
    assert Process.alive?(pid)
  end
end
