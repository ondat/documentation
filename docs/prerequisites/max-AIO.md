---
title: "Max AIO"
linkTitle: Max AIO
weight: 500
---

As part of the dataplane operation, Ondat uses Linux AIO (Asynchronous
Input Output) contexts to serve I/O requests without blocking. Ondat
requires 4 AIO contexts per deployment (i.e. an Ondat volume deployment,
whether master or replica).

## Max AIO prerequisite.
By default there is a maximum number of AIO contexts that can be allocated at
once.

The current and maximum number of AIO requests is visible in the virtual
files `/proc/sys/fs/aio-nr` and `/proc/sys/fs/aio-max-nr`.

The default context limit has been set at 2^16 or 65536. This figure may vary
so do check your `/proc/sys/fs/aio-max-nr`

When `aio-nr` reaches `aio-max-nr` the `io_setup` syscall will fail with
EAGAIN. For more information see the Linux kernel docs
[here.](https://www.kernel.org/doc/Documentation/sysctl/fs.txt)

## Why is this relevant?
As Ondat requires 4 AIO contexts per deployed volume, there is a limit to
the number of volumes that can be deployed per node. Trying to provision
additional deployments once the `aio-max-nr` has been reached will fail as the
kernel will be unable to create enough new AIO contexts.

## Increasing your AIO context cap.
If your nodes `aio-max-nr` is set too low you can either provision additional
nodes to reduce the number of deployments per node, or increase the `aio-max-nr`
kernel parameter.

You can do this by editing your `/etc/sysctl.conf` file with the following
example line:
```bash
fs.aio-max-nr = 1048576
```
To activate the new settings, run the following command:
```bash
$ sysctl -p /etc/sysctl.conf
```
