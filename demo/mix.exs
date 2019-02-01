defmodule NervesDnssdDemo.Mixfile do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"

  Mix.shell.info([:green, """
  Mix environment
    MIX_TARGET:   #{@target}
    MIX_ENV:      #{Mix.env}
  """, :reset])

  def project do
    [app: :nerves_dnssd_demo,
     version: "0.1.0",
     elixir: "~> 1.8",
     target: @target,
     archives: [nerves_bootstrap: "~> 1.4"],
     deps_path: "deps/#{@target}",
     build_path: "_build/#{@target}",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(@target),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application, do: application(@target)

  # Specify target specific application configurations
  # It is common that the application start function will start and supervise
  # applications which could cause the host to fail. Because of this, we only
  # invoke NervesDnssdDemo.start/2 when running on a target.
  def application("host") do
    [mod: {NervesDnssdDemo.Application, []},
    extra_applications: [:logger]]
  end
  def application(_target) do
    [mod: {NervesDnssdDemo.Application, []},
     extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  def deps do
    [{:nerves, "~> 1.4.0", runtime: false},
     {:shoehorn, "~> 0.4.0"},
     {:nerves_dnssd, path: ".."}] ++
    deps(@target)
  end

  # Specify target specific dependencies
  def deps("host"), do: []
  def deps(target) do
    [{:nerves_runtime, "~> 0.6.5"},
     {:nerves_network, "~> 0.3.7"},
     nerves_system(target)]
  end

  def nerves_system("qemu_arm"), do: {:"nerves_system_qemu_arm", "~> 1.0", runtime: false}
  def nerves_system(target), do: {:"nerves_system_#{target}", "~> 1.4", runtime: false}

  # We do not invoke the Nerves Env when running on the Host
  def aliases("host"), do: []
  def aliases(_target) do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

end
