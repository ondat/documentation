---
title: "Compression"
linkTitle: Compression
---

Ondat compression is handled on a per volume basis and is disabled by
default in v2.2+, as performance is generally increased when compression is
disabled due to block alignment. This means that there is a trade
off between volume performance and the space the volume occupies on the backend
device.

Compression can be enabled by setting the [label](/docs/reference/labels)
`storageos.com/nocompress=false` on a volume at volume creation time.

Ondat utilises the [lz4 compression algorithm](https://lz4.github.io/lz4/)
when writing to the backend store and when compressing [replication
traffic](/docs/concepts/replication) before it is sent across the network.

Ondat detects whether a block can be compressed or not by creating a
heuristic that predicts the size of a compressed block. If the heuristic
indicates that the compressed block is likely to be larger than the
original block then the uncompressed block is stored. Block size increases post
compression if the compression dictionary is added to a block that cannot be
compressed. By verifying whether blocks can be compressed, disk efficiency is
increased and CPU resources are not wasted on attempts to compress
uncompressible blocks. Ondat's patented on-disk format is used to tell
whether individual blocks are compressed without overhead. As such volume
compression can be dynamically enabled/disabled even while a volume is in use.

When compression and [encryption](/docs/concepts/encryption) are both enabled
for a volume, blocks are compressed then encrypted.


