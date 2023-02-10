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

<<<<<<< HEAD
### Hardware
=======
* Minimum two core with 4GB RAM
* Linux with a 64-bit architecture
* Kubernetes 1.21, 1.22, 1.23, 1.24 and 1.25
* OpenShift 4.8, 4.9, 4.10. 4.11 and 4.12
* Container Runtime Engine: CRI-O, Containerd or Docker 1.10+ with [mount propagation](/docs/prerequisites/mountpropagation) enabled
* The necessary ports should be open. See the [ports and firewall settings](/docs/prerequisites/firewalls)
* [Etcd cluster](/docs/prerequisites/etcd) for Ondat
* A mechanism for [device presentation](/docs/prerequisites/systemconfiguration)
>>>>>>> main

- For Ondat to successfully pool the attached storage disks in a Kubernetes cluster, an Ondat daemonset will be deployed where each pod will run on **worker nodes**:

#### Number Of Worker Nodes (Virtual or Bare-metal)

| **IoT/Edge** | **Minimum**               | **Recommended** |
| ------------ | ------------------------- | --------------- |
| `1`          | `3` for High Availability | `5` or greater  |

- Each worker node in cluster where Ondat will be deployed, should meet the following hardware requirements (minimum hardware requirements are recommended for evaluation purposes only):

#### Node Hardware Requirements

| **Requirement**                      | **Minimum** | **Recommended** |
| ------------------------------------ | ----------- | --------------- |
| CPU                                  | `1 Core`    | `4 Cores`       |
| Memory                               | `2 GB`      | `8 GB`          |
| Disk Storage (`/var/lib/storageos/`) | `2 GiB`     | `Unlimited`     |

> 💡 The requirements above will also be dependant on the stateful applications that will be running in your cluster, therefore, it is recommended to review your stateful applications resources requirements when factoring in requirements for Ondat.

### Architecture

| **Name**                                                  | **Supported**    |
| --------------------------------------------------------- | ---------------- |
| [`x86-64 (64)`](https://en.wikipedia.org/wiki/X86-64) bit | `Yes`            |
| [`arm64`](https://en.wikipedia.org/wiki/AArch64) bit      | `In Development` |

### Linux Kernel

- Below is the list supported Linux kernel versions and the maximum number of active volumes that can run per node in an Ondat cluster:

| **Kernel Version** | **Maximum Number Of Mounted Volumes Per Node Allowed** |
| ------------------ | ------------------------------------------------------ |
| `v3.x.x`           | `256`                                                  |
| `v4.x.x`           | `4096`                                                 |
| `v5.x.x`           | `4096`                                                 |
| `v6.x.x`           | `4096`                                                 |

### Linux Asynchronous I/O (AIO)

- When the Ondat Data plane component is operational, Ondat leverages [Linux Asynchronous I/O (AIO)](https://developer.ibm.com/articles/l-async/) contexts to initiate a number of I/O requests without having to block or wait for any to complete to process the next task - thus allowing you to boost performance for applications that are able to simultaneously overlap processing and I/O.
- The Linux kernel uses the [`/proc/sys/fs/aio-max-nr`](https://www.kernel.org/doc/Documentation/sysctl/fs.txt) virtual file to set the value of the maximum number of *allowable* AIO concurrent requests. The `/proc/sys/fs/aio-nr` virtual file also provides information on the current number of asynchronous requests on the node.
- Ondat requires `4` AIO contexts per deployed volume, whether it is a master or replica volume.
  - Trying to provision additional volumes once the `aio-nr` value reaches the `aio-max-nr`, will cause a `io_setup` system call to fail and return a [`EAGAIN` error](https://www.kernel.org/doc/Documentation/sysctl/fs.txt), meaning that the resource becomes temporarily unavailable.
- Therefore, if your nodes `aio-max-nr` kernel parameter value is less than `1048576`, a strong recommendation will be to set a new value in your `/etc/sysctl.conf` or through a custom configuration file in `/etc/sysctl.d/` to increase the number of AIO contexts that can be requested:

| Kernel Parameter | Value     |
| ---------------- | --------- |
| `fs.aio-max-nr`  | `1048576` |

> 💡 If your node(s) `aio-max-nr` kernel parameter value is less than `1048576`, the affected Ondat daemonset pods will report a warning error message in their logs.

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

### Supported Filesystems

#### Host/Node Filesystems

- Ondat uses the `/var/lib/storageos` path on each node as a base directory for storing its [configuration file and and blob files](/docs/concepts/volumes) related to the persistent volumes running in the cluster. Below are the list of node filesystem types that are supported by Ondat:

| **Supported Node Filesystems**               |
| -------------------------------------------- |
| [`ext4`](https://en.wikipedia.org/wiki/Ext4) |
| [`xfs`](https://en.wikipedia.org/wiki/XFS)   |

#### Ondat Persistent Volume Filesystems

- Ondat provides a block device on which a filesystem can be created. The creation of that filesystem is either handled by Ondat or by Kubernetes, which affects what filesystems can be created. When using the Ondat CSI (Container Storage Interface) driver, it will be responsible for running [`mkfs`](https://en.wikipedia.org/wiki/Mkfs) against the block device that the pod will mount. Below are the list of filesystems that Ondat is able to create for the persistent volumes:

| **Supported Persistent Volume Filesystem**s  |
| -------------------------------------------- |
| [`ext4`](https://en.wikipedia.org/wiki/Ext4) |
| [`xfs`](https://en.wikipedia.org/wiki/XFS)   |

> 💡 If the listed filesystems above are different from the one you are using, you can raise a feature request for it by contacting us through through our [Community Slack](https://slack.storageos.com/) or through the [Support Portal](/docs/support).

### Operating System

- Below is the following list of current Linux distributions (non-EOL) that are supported by Ondat:

| **Name**                                                                                                    | **Linux Distribution Support Notes**                                                                             |
| ----------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| [`Amazon Linux 2022 (AL2022)`](https://aws.amazon.com/linux/amazon-linux-2022/)                             | Yes - (Available from the **11th of November 2022** release on kernel `5.4.219-126.411.amzn2.x86_64` or greater) |
| [`Bottlerocket`](https://aws.amazon.com/bottlerocket/)                                                      | Yes - ([Snapshots feature](/docs/concepts/snapshots) available from `v2.10.0`)                                   |
| [`CentOS`](https://www.centos.org/)                                                                         | Yes                                                                                                              |
| [`Debian`](https://www.debian.org/)                                                                         | Yes                                                                                                              |
| [`Fedora`](https://getfedora.org/)                                                                          | Yes                                                                                                              |
| [`Google Container-Optimized OS (COS)`](https://cloud.google.com/container-optimized-os/)                   | Yes - (The required kernel modules are available, but the distribution has not undergone exhaustive testing yet) |
| [`openSUSE`](https://www.opensuse.org/)                                                                     | Yes                                                                                                              |
| [`SUSE Linux Enterprise Server (SLES)`](https://www.suse.com/products/server/)                              | Yes                                                                                                              |
| [`RedHat Enterprise Linux (RHEL)`](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux) | Yes ([Real-time kernel `rt-kernel`](https://access.redhat.com/solutions/4096521) is also supported)              |
| [`Ubuntu`](https://ubuntu.com/)                                                                             | Yes                                                                                                              |

> 💡 As a general rule of thumb, Ondat is agnostic and will run on any Linux distribution as long as the [required kernel modules prerequisites](#required-kernel-modules) are available and can be successfully loaded. In most modern Linux distributions, the key kernel modules are distributed as part of the default Linux kernel packages. In some older distributions, the kernel modules were part of the kernel `extras` package that needed to be installed separately.

> 💡 If you need help with a specific issue with one of the listed distributions we support, [raise an issue up on GitHub](https://github.com/ondat/documentation/issues) or reach out to us through our [Community Slack](https://slack.storageos.com/).

## Container Orchestrators

### Supported Kubernetes Distributions

| **Name**                                                                                                | **Supported Versions**                          |
| ------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| [`Kubernetes`](/docs/install/kubernetes)                                                                | Yes - (`v1.21`,`v1.22`,`v1.23`,`v1.24`,`v1.25`) |
| [`Amazon Elastic Kubernetes Service (EKS)`](/docs/install/aws)                                          | Yes - (`v1.21`,`v1.22`,`v1.23`,`v1.24`,`v1.25`) |
| [`Amazon EKS Anywhere`](/docs/install/aws)                                                              | Yes - (`v1.21`,`v1.22`,`v1.23`,`v1.24`,`v1.25`) |
| [`Microsoft Azure Kubernetes Service (AKS)`](/docs/install/azure)                                       | Yes - (`v1.21`,`v1.22`,`v1.23`,`v1.24`,`v1.25`) |
| [`DigitalOcean Kubernetes (DOKS)`](/docs/install/digitalocean)                                          | Yes - (`v1.21`,`v1.22`,`v1.23`,`v1.24`,`v1.25`) |
| [`Google Kubernetes Engine (GKE)`](/docs/install/gcp)                                                   | Yes - (`v1.21`,`v1.22`,`v1.23`,`v1.24`,`v1.25`) |
| [`Google Anthos`](/docs/install/gcp)                                                                    | Yes - (`v1.21`,`v1.22`,`v1.23`,`v1.24`,`v1.25`) |
| [`Red Hat OpenShift Container Platform (OCP)`](docs/install/openshift/openshift-container-platform-ocp) | Yes - (`v4.8`,`v4.9`,`v4.10`,`v4.11`,`v4.12`)   |
| [`MicroK8s`](docs/install/canonical)                                                                    | Yes - (`v1.26`)                                 |
| [`Rancher Kubernetes Engine (RKE)`](/docs/install/rancher)                                              | Yes - (`v1.21`,`v1.22`,`v1.23`,`v1.24`,`v1.25`) |
| [`Rancher Kubernetes Engine 2 (RKE2)`](/docs/install/rancher)                                           | Yes - (`v1.21`,`v1.22`,`v1.23`,`v1.24`,`v1.25`) |

### Container Runtimes

| **Name**                                    | **Supported Versions**                                                                                                                                                         |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [`containerd`](https://containerd.io/)      | Yes                                                                                                                                                                            |
| [`cri-o`](https://cri-o.io/)                | Yes                                                                                                                                                                            |
| [`docker`](https://docs.docker.com/engine/) | Yes - (Not supported from [Kubernetes `v1.24` as it has been deprecated](https://kubernetes.io/blog/2022/01/07/kubernetes-is-moving-on-from-dockershim/#deprecation-timeline)) |

### Mount Propagation

- It is required that [mount propagation](https://kubernetes-csi.github.io/docs/deploying.html#enabling-mount-propagation) is enabled for the container orchestrator where Ondat will be deployed in. Mount propagation is enabled by default in the newer release versions of Kubernetes and OpenShift.

| **Name**     | **Enabled Versions** |
| ------------ | -------------------- |
| `Kubernetes` | `v1.10` or greater   |
| `OpenShift`  | `v3.11` or greater   |

> 💡 If your container orchestrator has mount propagation disabled, and you are looking for guidance on how to enable it, review the [Kubernetes](https://kubernetes.io/docs/concepts/storage/volumes/#mount-propagation) and [OpenShift](https://docs.openshift.com/container-platform/3.11/install_config/storage_examples/mount_propagation.html) documentation on mount propagation for more information.

### Process ID (PID) Limits

- Ondat pods that are running in a Kubernetes or OpenShift cluster are part of a PID `cgroup` that may limit the maximum number of PIDs that all containers in the PID `cgroup` slice can spawn.
- As the Linux kernel assigns a PID to processes and [Light-Weight Processes (LWPs)](https://en.wikipedia.org/wiki/Light-weight_process), a low PID limit can be easily reached without breaching any other resource limits, which could then potentially cause instability issues as Ondat won’t be able to spawn new processes.
- Depending on the container orchestrator you are using, the PID limit is set by the distribution or the container runtime being used. Therefore, ensure that the [PID limit](https://kubernetes.io/docs/concepts/policy/pid-limiting/#pod-pid-limits/) is set to at least `32768` for Ondat pods in your cluster:

| Kubelet Parameter                  | Value   |
| ---------------------------------- | ------- |
| `--pod-max-pids` or `PodPidsLimit` | `32768` |

> 💡 To check if the PID limit of the PID `cgroup` slice that the Ondat pods runs in is set to at least `32768`, Ondat  will run an [init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) which conducts preflight checks to ensure that the correct limit is set. If your cluster defaults to a low PID limit, it is recommended to follow your distribution's documentation on how to configure and set a higher limit. Review the [Kubernetes - Configure Pod PID Limits](https://kubernetes.io/docs/concepts/policy/pid-limiting/#pod-pid-limits) and [OpenShift - Creating a ContainerRuntimeConfig CR to Edit CRI-O Parameters](https://docs.openshift.com/container-platform/latest/post_installation_configuration/machine-configuration-tasks.html#create-a-containerruntimeconfig_post-install-machine-configuration-tasks) documentation for guidance.

> ⚠️ OpenShift uses [CRI-O](https://cri-o.io/) as the container runtime, which has a PID limit that defaults to `1024`. It is strongly recommended that you raise the PID limit to at least `32768` to avoid instability issues.

## Networking

### Firewall Rules

For Ondat components to be able to successfully communicate with each other in a cluster, ensure that you add the following firewall rules or web proxy exceptions between nodes. Ensure that these ports are only **accessible inside the scope of a cluster** in your environment.

> 💡 Ondat also uses [ephemeral ports](https://en.wikipedia.org/wiki/Ephemeral_port) to dial-out to the ports listed below to other Ondat nodes in the cluster. For this reason, egress/outgoing traffic flows to other nodes is allowed.

> 💡 Ondat does not expose any service externally by default, ie each service is published with the [`ClusterIP`](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) service type which makes services only reachable from within a cluster.

| Ports         | Protocol      | Traffic Flow | Description                                                                        |
| ------------- | ------------- | ------------ | ---------------------------------------------------------------------------------- |
| `2379-2380`   | `TCP`         | `Two-way`    | [`etcd`](https://etcd.io/) communication for Ondat.                                |
| `5703`        | `TCP`         | `Ingress`    | DirectFS communication.                                                            |
| `5704`        | `TCP`         | `Ingress`    | [Ondat Data Plane](/docs/concepts/components/#ondat-data-plane) supervisor.        |
| `5705`        | `TCP`         | `Ingress`    | Ondat [REST](https://en.wikipedia.org/wiki/Representational_state_transfer) API.   |
| `5710`        | `TCP`         | `Ingress`    | Ondat [gRPC](https://en.wikipedia.org/wiki/GRPC) API.                              |
| `5711`        | `TCP` + `UDP` | `Ingress`    | [Gossip protocol](https://en.wikipedia.org/wiki/Gossip_protocol) communication.    |
| `8443`        | `TCP`         | `Egress`     | [Ondat Portal](https://portal.ondat.io/) communication.                            |
| `25705-25960` | `TCP`         | `Ingress`    | [Shared Filesystems - `ReadWriteMany` (RWX)](/docs/concepts/rwx) volume endpoints. |

### IPv6 Availability

- Although Ondat does not require `IPv6` addressing or routing to be configured in order to run successfully, specific Ondat components do require to be able to listen on a standard dual-stack [`AF_INET6`](https://www.ibm.com/docs/en/i/latest?topic=family-af-inet6-address) socket type and accept client requests from either `IPv4` or `IPv6` nodes.
- The `IPv6` address family must be supported in your cluster so that Ondat can leverage the `AF_INET6` socket type.

### Hardware Clock Synchronisation

- It is recommended that the [hardware/system clock](https://en.wikipedia.org/wiki/System_time) for the nodes in your cluster are correctly synchronised to use reliable [Network Time Protocol (NTP)](https://en.wikipedia.org/wiki/Network_Time_Protocol) servers.  
- While Ondat’s distributed consensus algorithm does not require synchronised hardware clocks, it is useful for troubleshooting through logs by being able to easily correlate logs across multiple Ondat nodes and prevent [clock drift](https://en.wikipedia.org/wiki/Clock_drift) in your cluster.
