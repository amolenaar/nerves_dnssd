defmodule NervesDnssdDemo.Application do
  use Application

  @interface :eth0

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    if Application.get_env(:nerves_dnssd_demo, :networking, true),
      do: Nerves.Networking.setup @interface

    # Define workers and child supervisors to be supervised
    children = [
      # worker(NervesMdnsDemo.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesDnssdDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
