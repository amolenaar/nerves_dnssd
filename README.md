# Nerves.Dnssd

[![Build Status](https://travis-ci.org/amolenaar/nerves_dnssd.svg?branch=master)](https://travis-ci.org/amolenaar/nerves_dnssd)
[![Hex.pm package](https://img.shields.io/hexpm/v/nerves_dnssd.svg)](https://hex.pm/packages/nerves_dnssd)
[![Hex.pm package](https://img.shields.io/hexpm/l/nerves_dnssd.svg)](https://hex.pm/packages/nerves_dnssd)

Nerves_dnssd provides an interface to Apple's Bonjour DNS Service Discovery
implementation. Bonjour allows applications to browse, resolve and register
network services via link-local multicast DNS on the local network and via
unicast DNS over the internet. In the later case if the service is running
behind a NAT gateway Bonjour will only advertise it if a port forward can be
negotiated via NAT-PMP or uPNP (which is attempted automatically).

This module is based on the `dnssd_erlang` project written by
[Andrew Tunnell-Jones](http://andrew.tj.id.au/),
[Radosław Szymczyszyn](https://github.com/erszcz/dnssd_erlang) and others.

## Installation

Nerves_dnssd requires Erlang R19 or later and Elixir 1.4.2 or later.

The package can be installed
by adding `nerves_dnssd` to your list of dependencies in `mix.exs`:

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

The examples have been translated to Elixir from the original (erlang) examples.

    $ iex -S mix

This will start the `nerves_dnssd` application and possibly an mDNS service.

In the success case, all functions return a tuple of the form `{:ok, reference}`.
Reference should be retained to pass to `:dnssd.stop/1` when no further results
are required. Please note that proper handing of references is omitted in the
examples below for simplicity and readability.

It's important to stop operations when no more results are needed to avoid
generating needless network traffic. To stop an operation pass the reference
returned when you started the operation to `:dnssd.stop/1`. Operations will also
be stopped if your process exits.

### Browsing for Services

```elixir
iex> :dnssd.browse("_http._tcp")
{:ok, #Reference<0.0.2.763>}
iex> flush()
{:dnssd, #Reference<0.0.2.763>,
 {:browse, :add, {"Foo", "_http._tcp.", "local."}}}
:ok
```

Results will be sent in tuples of the form
`{:dnssd, reference, {operation, change, result}}`. Reference will be the same
reference which was used to start the operation. Operation will be one of the
atoms `:browse`, `:resolve`, `:register` or `:enumerate`. Change will be the atom
`:add` or `:remove` and the result will be an operation specific term. For the
browse operation, it will be a tuple containing binaries of the form
`{service_name, service_type, domain}`.

```elixir
iex> :dnssd.browse("_http._tcp", "dns-sd.org")
{:ok, #Reference<0.0.4.1850>}
iex> flush()
{:dnssd, #Reference<0.0.4.1850>,
 {:browse, :add,
  {" * Apple, makers of the iPod", "_http._tcp.", "dns-sd.org."}}}
{:dnssd, #Reference<0.0.4.1850>,
 {:browse, :add,
  {" * Google, searching the Web", "_http._tcp.", "dns-sd.org."}}}
# …
:ok
```

Browsing can be limited to a specific domain by specifying the domain as
argument two. Both domains and service types may be specified as lists or
binaries.

### Resolving a Service Instance

To resolve a service, supply it's name, registration type and domain to the
resolve function.

```elixir
iex> :dnssd.resolve(" * DNS Service Discovery", "_http._tcp.", "dns-sd.org.")
{:ok, #Reference<0.0.4.1888>}
iex> flush()
{:dnssd, #Reference<0.0.4.1888>,
 {:resolve, {"dns-sd.org.", 80, [{"txtvers", "1"}, {"path", "/"}]}}}
:ok
```

Unlike the other operations results won't be tagged add or remove as the
underlying DNS-SD API does not provide this information. As resolve is generally
called just prior to connecting to a service this shouldn't pose a problem. The
Result term for this operation is a tuple of the form
`{hostname, port, txt_strings}` where `hostname` is a binary, `port` is an integer
and `txt_strings` is a list containing either binaries or should a given string
contain an equals sign, a `{key, value}` tuple wherein `key` is everything up to
the first equals sign and the remainder of the string is the value.

```elixir
iex> :dnssd.resolve_sync(" * DNS Service Discovery", "_http._tcp.", "dns-sd.org.")
{:ok, {"dns-sd.org.", 80, [{"txtvers", "1"}, {"path", "/"}]}}
```

A synchronous wrapper to resolve is also provided. A timeout in milliseconds can
also be specified by adding a fourth argument. The default timeout is 5 seconds.
`{:error, :timeout}` will be returned should the operation timeout.

### Registering Services

```elixir
iex> :dnssd.register("_answer._udp", 42)
{:ok, #Reference<0.0.4.1929>}
iex> flush()
{:dnssd, #Reference<0.0.4.1929>,
 {:register, :add, {"atj-mbp", "_answer._udp.", "local."}}}
:ok
```

The minimum arguments needed to register a service are the service type and
port. If no service name is supplied, the machines name is used (in the example
above, that's `"atj-mbp"`). The `result` term for this operation is a tuple
containing binaries of the form `{service_name, service_type, domain}`.

For brevity, the alternative invocations of register are:

```elixir
:dnssd.register(name, type, port)
:dnssd.register(type, port, txt)
:dnssd.register(name, type, port, txt)
:dnssd.register(name, type, port, txt, host, domain)
```

Wherein:

 * `txt` is a TXT record data in either binary form (a sequence of
`<<size, string:size/binary>>`), a list of atoms, strings or binaries or tuples
of the form `{key, value}` where `key` and `value` are atoms, strings or binaries.
 * `host` is the hostname of the machine running the service. Pass an empty
string or binary for the local machine.
 * `domain` is the domain to register the service within. Pass an empty string
or binary for all domains.

***Note:*** A service may be renamed if it conflicts with another service. Check
the Results tuple to determine what name a service has been assigned.

#### Local Registrations

If `localhost` is passed as `host` to `:dnssd.register/6` the service will be
registered only in the local domain (regardless of the `domain` argument) and only
on the local machine.

### Enumerating Domains

```elixir
iex> :dnssd.enumerate(:browse)
{:ok, #Reference<0.0.4.1947>}
iex> flush()
{:dnssd, #Reference<0.0.4.1947>, {:enumerate, :add, "local."}}
{:dnssd, #Reference<0.0.0.1947>, {:enumerate, :add, "bonjour.tj.id.au."}}
:ok
```

```elixir
iex> :dnssd.enumerate(:reg)
{:ok, #Reference<0.0.4.1962>}
iex> flush()
{:dnssd, #Reference<0.0.4.1962>, {:enumerate, :add, "local."}}
{:dnssd, #Reference<0.0.4.1962>, {:enumerate, :add, "bonjour.tj.id.au."}}
:ok
```

The result term for this operation is a binary containing the browse or
registration domain.

### Retrieving Results

Results from a running operation can be retrieved by calling
`:dnssd.results(ref)`. For resolve operations this will only return the last
result. For all other operations it will return all current results.
