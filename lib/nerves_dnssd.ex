defmodule Nerves.Dnssd do
  @moduledoc """
  Start the mdns daemon as a port process.
  """

  @doc """
  """
  def start do
    # Start mdnsd supervisor
    {:ok, self()}
  end

  defmodule Daemon do

    def start_link do
      GenServer.start_link(__MODULE__, [])
    end

    ## Server callbacks

    def init([]) do
      port = Port.open({:spawn_executable, :code.priv_dir(:nerves_dnssd) ++ '/sbin/mdnsd'}, [:exit_status, args: ['-debug'], line: 256])
      {:ok, port}
    end

    def handle_info({_, {:data, {:eol, message}}}, _port) do
      IO.inspect message, label: "mdnsd"
    end

    def handle_info(info, _port) do
      IO.inspect info, label: "mdnsd unknown"
    end

    def terminate(_reason, port) do
      Port.close(port)
      :ok
    end

  end

end
