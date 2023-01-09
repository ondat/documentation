---
title: "Prerequisites"
linkTitle: "Prerequisites"
weight: 300
description: >
  Key prerequisites and system requirements to deploy Ondat.
---

## Overview

- This page provides information on the requirements that are required to successfully run Ondat on your container orchestrator. Ensure that you have met the requirements before attempting to do an Ondat deployment.

## System Requirements

### Hardware

- For Ondat to successfully pool the attached storage disks in a Kubernetes cluster, an Ondat daemonset will be deployed where each pod will run on **worker nodes**:

**Number Of Worker Nodes (Virtual or Bare-metal)**

| **Minimum** | **Recommended** |
| ----------- | --------------- |
| `3`         | `5 or more`     |

- Each worker node in cluster where Ondat will be deployed, should meet the following hardware requirements:

**Node Hardware Requirements**

| **Requirement**                 | **Minimum** | **Recommended** |
| ------------------------------- | ----------- | --------------- |
| CPU                             | `2 Cores`   | `4 Cores`       |
| Memory                          | `4 GB`      | `8 GB`          |
| Storage (`/var/lib/storageos/`) | `1 GiB`     | `Unlimited`     |

### Architecture

| **Name**                                                | **Supported** |
| ------------------------------------------------------- | ------------- |
| [x86-64 (64)](https://en.wikipedia.org/wiki/X86-64) bit | `Yes`         |
| [arm64](https://en.wikipedia.org/wiki/AArch64) bit      | `Coming Soon` |

### Linux Kernel

- Below is the list supported Linux kernel versions and the maximum number of active volumes that can run per node in an Ondat cluster:

| **Kernel Version** | **Maximum Number Of Active Volumes Per Node Allowed** |
| ------------------ | ----------------------------------------------------- |
| `3.x.x`            | `256`                                                 |
| `4.x.x`            | `4096`                                                |
| `5.x.x`            | `4096`                                                |
| `6.x.x`            | `4096`                                                |

### Required Kernel Modules

- Ondat requires the open source [LinuxIO (LIO) SCSI target](https://en.wikipedia.org/wiki/LIO_(SCSI_target)) engine that has been built into the Linux kernel mainline, since [kernel version 2.6.38](https://en.wikipedia.org/wiki/Linux_kernel_version_history#Releases_2.6.x.y).  
- Below are the following kernel modules that are required to be loaded on your worker nodes operating system where Ondat will be deployed:

| **Kernel Modules** |
| ------------------ |
| `configfs`         |
| `target_core_mod`  |
| `target_core_user` |
| `tcm_loop`         |
| `uio`              |

> ⚠️ You cannot concurrently run Ondat and other applications that utilise [TCMU](https://www.kernel.org/doc/Documentation/target/tcmu-design.txt). Doing so will result in data loss and corruption. On startup, Ondat will automatically detect if there are other applications that utilise TCMU to avoid data loss and corruption.

- Once the kernel modules are available, during the deployment process - Ondat will run an [init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) which conducts preflight checks to ensure that the kernel modules are loaded and ready to be used by the Ondat daemonset that runs on each worker node.

### Operating System
