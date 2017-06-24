defmodule Nerves.Dnssd.Mixfile do
  use Mix.Project

  def project do
    [app: :nerves_dnssd,
     version: "0.1.0",
     description: "Bonjour/Zeroconf DNS Service Discovery for the Nerves platform",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
     docs: docs(),
     package: package(),
     compilers: [:elixir_make] ++ Mix.compilers,
     make_env: %{
       "BUILD_DIR"   => Mix.Project.build_path()
     },
     make_clean: ["clean"]]
  end

  def application do
    [mod: {Nerves.Dnssd, []},
     extra_applications: [:logger]]
  end

  defp aliases do
    ["test": ["test", "eunit"]]
  end

  defp deps do
    [{:elixir_make, "~> 0.4", runtime: false},
     {:mix_eunit, "~> 0.3.0", runtime: false},
     {:ex_doc, "~> 0.15.1", only: :dev, runtime: false},
     {:credo, "~> 0.7.4", only: :dev, runtime: false},
     {:dialyxir, "~> 0.4", only: :dev, runtime: false}]
  end

  defp docs do
    [main: "readme",
     extras: [
       "README.md",
       "overview.md"]]
  end

  def package do
    [licenses: ["Apache 2.0"],
     maintainers: ["Arjan Molenaar"],
     files: ["lib", "src", "c_src", "priv/mdns-wrapper", "LICENSE", "mix.exs", "Makefile", "README.md", "overview.md"],
     links: %{"GitHub" => "https://github.com/amolenaar/nerves_dnssd"}]
  end
end
