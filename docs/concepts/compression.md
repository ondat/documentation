---
title: "Ondat Compression"
linkTitle: "Ondat Compression"
weight: 1
---

## Overview

> 💡 This feature is disabled by default in in release `v2.2.0` or greater.

### Data Compression

Ondat compression is handled on a per volume basis and is disabled in `v2.2.0`, as performance is generally increased when compression is disabled due to [block alignment](https://en.wikipedia.org/wiki/Data_structure_alignment). 
- This means that there is a trade off between volume performance and the space the volume occupies on the backend device.

Ondat utilises the [LZ4 (compression algorithm)](https://en.wikipedia.org/wiki/LZ4_%28compression_algorithm%29) when writing to the backend store and when compressing Ondat [replication traffic](/docs/concepts/replication) before it is sent across the network.

Ondat detects whether a block can be compressed or not by creating a heuristic that predicts the size of a compressed block. 
- If the heuristic indicates that the compressed block is likely to be larger than the original block then the uncompressed block is stored. 
- Block size increases post compression if the compression dictionary is added to a block that cannot be compressed. By verifying whether blocks can be compressed, disk efficiency is increased and CPU resources are not wasted on attempts to compress incompressible blocks. 
- Ondat's patented on-disk format is used to tell whether individual blocks are compressed without overhead. As such volume compression can be dynamically enabled/disabled even while a volume is in use.

### How To Enable Ondat Compression?

Compression can be enabled by setting the [Ondat Feature Label](/docs/concepts/labels) > `storageos.com/nocompress=false` on a volume at volume creation time.

### Ondat Compression & Data Encryption

When Ondat compression and [data encryption](/docs/concepts/encryption) are both enabled for a volume, blocks are **compressed first** and then encrypted.
