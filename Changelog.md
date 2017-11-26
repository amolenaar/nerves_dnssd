# Release history

Below you'll find the release history of `nerves_dnssd`.

## 0.3.0

 * Added interface `Nerves.Dnssd.register()`, for straightforward persistent registration.
 * Updated mDNSResponder to 878.1.1
 * `mdnsd` binary is now properly stripped (slimmed down).

## 0.2.0

 * Mdnsd is patched to behave correctly when started using a port.
 * Wrapper script is no longer needed.

## 0.1.0

 * Initial release.mix
 * Mdnsd is launched via a wrapper script.
