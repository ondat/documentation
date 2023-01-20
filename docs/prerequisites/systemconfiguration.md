---
title: "System Configuration"
linkTitle: System Configuration
weight: 100
---

Ondat requires certain standard kernel modules to function. In particular it requires [Linux-IO (LIO)](https://en.wikipedia.org/wiki/LIO_(SCSI_target)), an open-source implementation of the SCSI target, on all nodes that will execute Ondat (usually the workers).  A variety of Linux distributions are made available by AWS/Azure/GCP and other hyperscalers for use within their kubernetes platforms, however note that not all of them ship with Linux-IO.

## Supported Distributions

Current (non-EOL) versions of the following distributions are supported by default:

* SUSE Linux Enterprise Server
* Red Hat Enterprise Linux (also supported with real-time kernel)
* CentOS
* Debian
* Ubuntu
* Amazon Linux 2/2022 (11th November 2022 release with Kernel 5.4.219-126.411.amzn2.x86_64 or above)
* Bottlerocket (currently doesn't support [Snapshots](/docs/concepts/snapshots/))

The following distributions include the prerequisite modules but are not yet tested exhaustively by the Ondat team:

* Google ContainerOS

> 💡 If you require help with a specific issue with a listed distribution, [raise an issue on GitHub](https://github.com/ondat/documentation/issues) or reach out to us on our [Community Slack](https://slack.storageos.com)

## Kernel Modules

We require the following modules to be loaded:

* `target_core_mod`
* `tcm_loop`
* `configfs`
* `target_core_user`
* `uio`

> ⚠️ Other applications utilising [TCMU](https://docs.kernel.org/target/tcmu-design.html) cannot be run concurrently with Ondat. Doing so may result in corruption of data. On startup, Ondat will detect if other applications are using TCMU.

In most modern distributions, including those listed above, the modules are distributed as part of the Linux kernel package and are included by default. In some older distributions, they were part of a kernel extras package that needed to be installed separately.

## Installing the required Kernel Modules

The script [enable-lio.sh](https://github.com/storageos/init/blob/master/scripts/01-lio/enable-lio.sh) from Ondat's init container can be used to ensure that all kernel-level dependencies are installed, any errors will indicate which components are missing.

For example, in Ubuntu versions prior to 22.04 several modules were not included in the base kernel configuration. Run the following command to install `linux-modules-extra` to obtain these additional modules required for Ondat:

```shell
sudo apt-get update
sudo apt-get install -y linux-modules-extra-$(uname -r)
```

## Automatic Configuration

Once required kernel modules are installed on the system, for convenience we provide a container that will ensure the appropriate modules are loaded and ready for use at runtime. You will need to run the init container prior to starting Ondat.  Our installation guides for Kubernetes and OpenShift include this step.

## Manual Configuration

For those wishing to manage their own kernel configuration, rather than using the init container, perform the following steps:

1. Ensure kernel modules are all loaded per list above
1. Ensure configfs is loaded and mounted at `/sys/kernel/config`
