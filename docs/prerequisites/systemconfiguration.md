---
title: "System Configuration"
linkTitle: System Configuration
weight: 100
---

Ondat requires certain kernel modules to function. In particular it requires [Linux-IO](http://linux-iscsi.org/wiki/Main_Page), an open-source implementation of the SCSI target, on all nodes that will execute Ondat (usually the workers).

## Distribution Specifics

Current (non-EOL) versions of the following distributions are supported by default:

* SUSE Linux Enterprise Server
* Red Hat Enterprise Linux
* CentOS
* Debian
* Ubuntu

The following distributions include the prerequisite modules but are not yet tested exhaustively by the Ondat team:

* Bottlerocket
* Google ContainerOS

The following distributions are currently not supported:

* Amazon Linux (lacks `target_core_mod` and `target_core_user`)
* RancherOS (CSI is not supported on RancherOS)

> 💡 If you require help with a specific issue with a listed distribution, [raise an issue on GitHub](https://github.com/ondat/documentation/issues) or reach out to us on our [Community Slack](https://slack.storageos.com)

## Kernel Modules

We require the following modules to be loaded:

* `target_core_mod`
* `tcm_loop`
* `configfs`
* `target_core_user`
* `uio`

> ⚠️ Other applications utilising [TCMU](http://linux-iscsi.org/wiki/LIO) cannot be run concurrently with Ondat. Doing so may result in corruption of data. On startup, Ondat will detect if other applications are using TCMU.

Depending on the distribution, the modules are shipped as part of the base kernel package or as part of a kernel extras package which needs to be installed.

## Automatic Configuration

Once required kernel modules are installed on the system, for convenience we
provide a container which will ensure the appropriate modules are loaded and
ready for use at runtime. You will need to run the init container prior to starting Ondat.  
Our installation guides for Kubernetes and OpenShift include this step.

## Manual Configuration

For those wishing to manage their own kernel configuration, rather than using
the init container, perform the following steps:

* Ensure kernel modules are all loaded per list above
* Ensure configfs is loaded and mounted at /sys/kernel/config
