defmodule MdnsWrapperTest do
  use ExUnit.Case

  test "mdns-wrapper should die when child dies" do
    port = mdns_wrapper "shortlived.sh"

    assert_receive {^port, {:data, {:eol, 'done'}}}
    assert_receive {^port, {:exit_status, 0}}
  end

  test "mdns-wrapper should terminate child process when interrupted." do
    port = mdns_wrapper "mdnsd-stub.sh"
    child_processes = find_child_processes port

    Port.close port

    assert_processes_do_not_exist(child_processes)
  end

  defp mdns_wrapper(subject) do
    executable = System.cwd()
    |> Path.join("test")
    |> Path.join(subject)

    {:ok, port} = Nerves.Dnssd.Daemon.init [executable]
    port
  end

  defp find_child_processes(port) do
    os_pid = Port.info(port) |> Keyword.get(:os_pid)

    {lines, 0} = System.cmd("pgrep", ["-P", "#{os_pid}"], into: [])

    lines
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
  end

  defp assert_processes_do_not_exist(procs) do
    procs
    |> Enum.map(fn (proc) ->
      assert {_, 1} = System.cmd("ps", ["-p", "#{proc}"])
    end)
  end
end
