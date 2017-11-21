# Nerves.Dnssd

Nerves_dnssd provides an interface to Apple's Bonjour DNS Service Discovery
implementation. Bonjour allows applications to browse, resolve and register
network services via link-local multicast DNS on the local network and via
unicast DNS over the internet.

This module is based on the Dnssd_erlang project written by
[Andrew Tunnell-Jones](http://andrew.tj.id.au/),
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

If you are running Linux with Avahi you will need Avahi's Bonjour compatibility
layer installed. If `{error,-65537}` is returned when starting an operation
it may be that avahi-daemon is not running.

This module has not been tested on Windows.

## Example use

The examples below demonstrate how to use the service discovery interface.
An end-to-end example can be found in the
[demo folder](https://github.com/amolenaar/nerves_dnssd/tree/master/demo).

```shell
$ iex -S mix
```

This will start the Nerves_dnssd application and optionally an mDNS service.

In the most basic situation, where one wants to simply register a service
on the network, calling

```elixir
{:ok, pid} = Nerves.Dnssd.register("Fancy service name", "_http._tcp", 8080)
```

is sufficient to register a HTTP service listening on port 8080. In case there is
already a service named "Fancy service name" a new name will be determined by
using a follow-up number and that name will be registered, so that after a restart
the service will advertise itself with the same name.

If you want to do more, you'll have to use the [`:dnssd` interface](dnssd.html).

## License

This project is distributed under the Apache License, version 2.0. The conditions can
be found in the LICENSE file.
# About Bonjour

Nerves_dnssd provides an interface to Apple's DNS Service Discovery API. DNS
Service Discovery enables applications to advertise and discover services both
peer to peer on the local network using multicast DNS and over the internet
using traditional unicast DNS and if needed NAT-PMP or uPNP for port forwarding.

Bonjour and the DNS-SD API are bundled with OS X. On Windows Bonjour is bundled
with some Apple applications and is also available standalone in the form of
[Bonjour Print Services for Windows](<http://support.apple.com/kb/DL999).
The DNSSD API is made available via
[Bonjour SDK for Windows](https://connect.apple.com/cgi-bin/WebObjects/MemberSite.woa/wa/getSoftware?bundleID=20737) (free registration required).

On other UNIX like platforms the DNSSD API can be made available via either
[Apple mDNSResponder](http://svn.macosforge.org/repository/mDNSResponder/trunk/) or [Avahi](http://avahi.org) with it's optional
Bonjour compatibilty layer. The former tends to be more commonly used on BSD
and embedded platforms while the later is a mainstay of most Linux desktop
operating systems. They are mostly functionally equivalent except in the area of
wide-area service discovery where Avahi does not support registering in
wide-area domains or DNS-LLQ for real-time updates.

*Note:* Problems will ensue should multiple daemons be run on one machine.

For further information on the DNS Service Discovery API or Bonjour itself, see
[Apple's Bonjour developer page](http://developer.apple.com/networking/bonjour).
