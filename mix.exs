defmodule Mix.Tasks.Compile.MdnsResponder do
  def run(_args), do: make("all")

  def clean(_args), do: make("clean")

  defp make(target) do
    Mix.shell.info("===> Compiling mdnsd binary")
    if match? {:win32, _}, :os.type do
      # We do not support Windows fow now.
      Mix.raise("Windows is not supported")
    else
      env = [
        {"BUILD_DIR", Mix.Project.build_path()},
        {"INSTALL_DIR", Mix.Project.build_path() <> "/lib/nerves_dnssd"}
      ]

      case System.cmd("make", [target], into: [], env: env) do
        {_stdout, 0} -> :ok
        {stdout, exit_code} ->
          ["--------- Makefile output ----------\n"] ++
            stdout ++
            ["------ End of Makefile output ------\n"]
          |> Enum.map(fn (line) -> IO.write line end)

          Mix.raise("Build of mDNS daemon and library failed (#{inspect exit_code})")
          exit({:shutdown, exit_code})
      end
    end
  end
end

defmodule Nerves.Dnssd.Mixfile do
  use Mix.Project

  def project do
    [app: :nerves_dnssd,
     version: "0.2.1",
     description: "Bonjour/Zeroconf DNS Service Discovery for the Nerves platform",
     elixir: "~> 1.5",
     build_embedded: true,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
     docs: docs(),
     package: package(),
     compilers: [:mdns_responder] ++ Mix.compilers]
  end

  def application do
    [mod: {Nerves.Dnssd, []},
     extra_applications: [:logger]]
  end

  defp aliases do
    ["test": ["test", "eunit"]]
  end

  defp deps do
    [{:system_registry, "~> 0.6.0"},
     {:mix_eunit, "~> 0.3.0", runtime: false},
     {:ex_doc, "~> 0.18.1", only: :dev, runtime: false},
     {:credo, "~> 0.8.1", only: :dev, runtime: false},
     {:dialyxir, "~> 0.4", only: :dev, runtime: false}]
  end

  defp docs do
    [main: "readme",
     extras: [
       "README.md",
       "overview.md",
       "Changelog.md"]]
  end

  def package do
    [licenses: ["Apache 2.0"],
     maintainers: ["Arjan Molenaar"],
     files: ["lib", "src", "c_src", "LICENSE", "mix.exs", "Makefile", "README.md", "overview.md", "Changelog.md"],
     links: %{"GitHub" => "https://github.com/amolenaar/nerves_dnssd"}]
  end
end
