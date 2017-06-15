defmodule Nerves.Dnssd.Mixfile do
  use Mix.Project

  def project do
    [app: :nerves_dnssd,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     compilers: [:elixir_make] ++ Mix.compilers,
     make_env: %{ "BUILD_DIR" => Mix.Project.build_path() }]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [ # mod: {:dnssd_app, []},
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
  defp deps do
    [{:elixir_make, "~> 0.4", runtime: false}]
  end
end
