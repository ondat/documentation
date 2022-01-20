---
title: "Availability of IPv6"
linkTitle: Availability of IPv6
weight: 200
---

## Availability of IPv6 Address Family
Certain Ondat components need to be able to listen on a standard
dual-stack socket of type AF_INET6. The IPv6 address family must be supported
on the server so that this socket can be allocated. Ondat does not require
IPv6 to be configured on the server - no addressing or routing needs to be in
place, however Ondat does need this functionality to be enabled in the
kernel.