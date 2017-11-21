# Nerves.Dnssd

[![Build Status](https://travis-ci.org/amolenaar/nerves_dnssd.svg?branch=master)](https://travis-ci.org/amolenaar/nerves_dnssd)
[![Hex.pm package](https://img.shields.io/hexpm/v/nerves_dnssd.svg)](https://hex.pm/packages/nerves_dnssd)
[![Hex.pm package](https://img.shields.io/hexpm/l/nerves_dnssd.svg)](https://hex.pm/packages/nerves_dnssd)

Nerves_dnssd provides an interface to Apple's Bonjour DNS Service Discovery
implementation. Bonjour allows applications to browse, resolve and register
network services via link-local multicast DNS on the local network and via
unicast DNS over the internet.

This module is based on the [Dnssd_erlang](https://github.com/erszcz/dnssd_erlang)
project written by [Andrew Tunnell-Jones](http://andrew.tj.id.au/),
[Radosław Szymczyszyn](https://github.com/erszcz/dnssd_erlang) and others.

## Installation

Nerves_dnssd requires Erlang R19 or later and Elixir 1.5.0 or later.

The package can be installed
by adding Nerves_dnssd to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:nerves_dnssd, "~> x.y"}]
end
```

Further documentation can be found on the (HexDocs page for Nerves_dnssd)[https://hexdocs.pm/nerves_dnssd/].

## Example use

In the most basic situation, where one wants to simply register a service
on the network, calling

```elixir
{:ok, pid} = Nerves.Dnssd.register("Fancy service name", "_http._tcp", 8080)
```

is sufficient to register a HTTP service listening on port 8080. In case there is
already a service named "Fancy service name" a new name will be determined by
using a follow-up number and that name will be registered, so that after a restart
the service will advertise itself with the same name.

## License

This project is distributed under the Apache License, version 2.0. The conditions can
be found in the LICENSE file.
