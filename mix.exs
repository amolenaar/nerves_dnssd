defmodule Nerves.Dnssd.Mixfile do
  use Mix.Project

  def project do
    [app: :nerves_dnssd,
     version: "0.1.0",
     desciption: "Apple Bonjour DNS Service Discovery for the Nerves platform",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
     compilers: [:elixir_make] ++ Mix.compilers,
     make_env: %{
       "BUILD_DIR"   => Mix.Project.build_path()
     },
     make_clean: ["clean"]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [mod: {Nerves.Dnssd, []},
     extra_applications: [:logger]]
  end

  defp aliases do
    ["test": ["test", "eunit"]]
  end

  defp deps do
    [{:elixir_make, "~> 0.4", runtime: false},
     {:mix_eunit, "~> 0.3.0", runtime: false}]
  end
end
