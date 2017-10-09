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
[http://developer.apple.com/networking/bonjour].
