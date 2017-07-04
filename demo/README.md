# Nerves DNS-SD demo

This project contains a small demo app for the `nerves_dnssd` project.

The idea is to launch 2 QEMU emulators, each running an instance of the demo app.
Both instances will start their own Bonjour daemon and will announce themselves
over the local network.

# Getting stuff set up with QEMU

## Mac OS X

Install QEMU with VDE support, so we can set up a private network

    $ brew install qemu --with-vde

Now let's start up a network in two separate terminals:

    $ vde_switch -F -sock /tmp/switch1

    $ slirpvde -s /tmp/switch1 -dhcp

Launch one instance of the demo app:

    $ ./launch.sh

When the emulator is booting, launch another:

    $ ./launch.sh

If you experience exceptions when launching, you may want to remove the
`_build` and the `priv` folder in the `nerves_dnssd` project. There is a fair
chance the applications are not compiled for the ARM platform. This is less of
a problem when you include the app as a normal dependency.


The daemon process and our dnssd application will automatically start in both emulators:

    mDNSResponder (Engineering Build) (Jun 15 2017 23:37:07) starting
    setsockopt - SO_RECV_ANYIF: Protocol not available
    mDNS_AddDNSServer: Lock not held! mDNS_busy (0) mDNS_reentrancy (0)
    CheckNATMappings: Failed to allocate port 5350 UDP multicast socket for PCP & NAT-PMP announcements

Warnings as shown above are no problem for a well-functioning demo.


In one emulator, let's start browsing for HTTP services:

    iex> {:ok, ref} = :dnssd.browse("_http._tcp")
    {:ok, #Reference<0.0.1.2473>}

Now let's register a service from the other emulator:

    iex> :dnssd.register("Cool service", "_http._tcp", 8000)
    {:ok, #Reference<0.0.1.2536>}

In the second emulator, call `flush()`, we receive messages on the new service
being registered:

    iex> flush()
    {:dnssd, #Reference<0.0.1.2473>,
     {:browse, :add, {"Cool service", "_http._tcp.", "local."}}}
    :ok

Another way to receive results is by calling the `results` functions (this is
the synchronous way):

    iex> :dnssd.results(ref)
    {:ok, [{"Cool service", "_http._tcp.", "local."}]}

We can also resolve this service and quory for IP information:

    iex> {:ok, res} = :dnssd.resolve("Cool service", "_http._tcp.", "local.")
    {:ok, #Reference<0.0.1.2882>}

    iex> flush()
    {:dnssd, #Reference<0.0.1.2515>, {:resolve, {"nerves-0000.local.", 8000, [""]}}}
    :ok

Shut down the emulator in which we registered the service. Invoking `flush()`
again in the other browser will tell you that the service is gone:

    iex> {:ok, res} = :dnssd.resolve("Cool service", "_http._tcp.", "local.")
    {:ok, #Reference<0.0.1.2882>}

After a little while, you'll receive a notification that the service is gone:

    iex> flush()
    {:dnssd, #Reference<0.0.1.2466>,
     {:browse, :remove, {"Cool service", "_http._tcp.", "local."}}}
    :ok


## Work in progress

### Distributed Erlang over Bonjour

    $ mix compile
    $ iex --erl "-proto_dist dnssd -start_epmd false -epmd_module dnssd_epmd_stub -pa _build/host/dev/lib/nerves_dnssd_demo/ebin" --sname demo1 --cookie demo -S mix

Start a second instance with a slightly different `sname` (e.g. `demo2`).

Now spawn a job on the first node from the second:

    iex(demo2@mynode)> Node.spawn :"demo1@mynode", fn () -> IO.puts "Hello world" end

The nodes are linked!

    iex(demo1@mynode)> :erlang.nodes
    [:"demo2@mynode"]


Start a remote shell:

    iex(demo1@mynode)> Node.spawn :"demo2@mynode", fn -> IEx.start end


TODO: put the node name in a Txt field and use a human readable name as lookup name. Does this work?

