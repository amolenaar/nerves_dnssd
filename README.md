# Nerves.MDNS

A mDNS (Bonjour) service for the Nerves platform. The real Bonjour (mDNSReponder)
binaries are used, to provide 100% compatibility.

This service should be used in conjunction with the dnssd_erlang library.

## Installation

Once [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `nerves_mdns` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:nerves_mdnsd, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/nerves_mdns](https://hexdocs.pm/nerves_mdns).

