defmodule Nerves.Dnssd.Daemon do
  @moduledoc """
  Process for managing the mdnsd daemon.

  It should just keep running.
  """

  def start do
    GenServer.start(__MODULE__, [])
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  ## Server callbacks

  def init([]) do
    port = Port.open({:spawn_executable, :code.priv_dir(:nerves_dnssd) ++ '/sbin/mdnsd'}, [:exit_status, args: ['-debug']])
    {:ok, port}
  end

  def handle_info({_, {:data, {:eol, message}}}, port) do
    IO.inspect message, label: "mdnsd"
    {:noreply, port}
  end

  def handle_info({port, {:exit_status, 0}}, port) do
    {:stop, :normal, port}
  end

  def handle_info({port, {:exit_status, status}}=info, port) do
    IO.inspect info, label: "mdnsd info"
    {:stop, {:mdnsd_exited, status}, port}
  end

  def handle_info(info, port) do
    IO.inspect info, label: "mdnsd info"
    {:noreply, port}
  end

  def terminate(thing, state) do
    IO.inspect thing, label: "first arg"
    IO.inspect state, label: "state"
  end
end
