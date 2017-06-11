defmodule Nerves.Mdnsd do
  @moduledoc """
  Start the mdns daemon as a port process.
  """

  @doc """
  """
  def start do
    # Start mdnsd supervisor
  end

  def start_link do
    # TODO: open a port, start mdnsd -debug
  end

  def start_daemon do
    Port.open({:spawn_executable, :code.priv_dir(:nerves_mdnsd) ++ '/sbin/mdnsd'}, [:binary, args: ['-debug']])
  end
end
