defmodule Nerves.Dnssd.Daemon do
  @moduledoc """
  Process for managing the mdnsd daemon.

  It should just keep running.
  """

  require Logger

  def start do
    GenServer.start(__MODULE__, [])
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  ## Server callbacks

  def init([]) do
    port = Port.open({:spawn_executable, :code.priv_dir(:nerves_dnssd) ++ '/mdns-wrapper'},
                     [:exit_status, :stderr_to_stdout, cd: :code.priv_dir(:nerves_dnssd), line: 256])
    {:ok, port}
  end

  def handle_info({_port, {:data, {:eol, 'ERROR: ' ++ message}}}, port) do
    Logger.error message
    {:noreply, port}
  end

  def handle_info({_port, {:data, {:eol, 'WARNING: ' ++ message}}}, port) do
    Logger.warn message
    {:noreply, port}
  end

  def handle_info({_port, {:data, {:eol, message}}}, port) do
    Logger.info message
    {:noreply, port}
  end

  def handle_info({port, {:exit_status, 0}}, port) do
    {:stop, :normal, port}
  end

  def handle_info({port, {:exit_status, status}}, port) do
    Logger.warn "mdns daemon stopped with exit code #{status}, #{Port.info(port)}"
    {:stop, {:mdnsd_exited, status}, port}
  end

  def handle_info(info, port) do
    Logger.warn "Unexpected message: #{inspect info}"
    {:noreply, port}
  end

end
