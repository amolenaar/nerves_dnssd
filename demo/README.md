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

    $ ./launch.sh 1

And another one:

    $ ./launch.sh 2

If you experience exceptions when launching, you may want to remove the
`_build` and the `priv` folder in the `nerves_dnssd` project. There is a fair
chance the applications are not compiled for the ARM platform. This is less of
a problem when you include the app as a normal dependency.

Ensure yourself that both emulations have received unique IP addresses.

Start the daemon process and our dnssd application in both emulators:

    iex> Nerves.Dnssd.Daemon.start_link
    {:ok, #PID<0.118.0>}
    iex(2)> mDNSResponder (Engineering Build) (Jun 15 2017 23:37:07) starting
    setsockopt - SO_RECV_ANYIF: Protocol not available
    mDNS_AddDNSServer: Lock not held! mDNS_busy (0) mDNS_reentrancy (0)
    CheckNATMappings: Failed to allocate port 5350 UDP multicast socket for PCP & NAT-PMP announcements

    iex> :dnssd_app.start
    {:ok, #PID<0.121.0>}

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


