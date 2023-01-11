
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
| `3`         | `5` or greater  |

- Each worker node in cluster where Ondat will be deployed, should meet the following hardware requirements:

**Node Hardware Requirements**

| **Requirement**                      | **Minimum** | **Recommended** |
| ------------------------------------ | ----------- | --------------- |
| CPU                                  | `2 Cores`   | `4 Cores`       |
| Memory                               | `4 GB`      | `8 GB`          |
| Disk Storage (`/var/lib/storageos/`) | `1 GiB`     | `Unlimited`     |

### Architecture

| **Name**                                                | **Supported** |
| ------------------------------------------------------- | ------------- |
| [`x86-64 (64)`](https://en.wikipedia.org/wiki/X86-64) bit | `Yes`         |
| [`arm64`](https://en.wikipedia.org/wiki/AArch64) bit      | `Coming Soon` |

### Linux Kernel

- Below is the list supported Linux kernel versions and the maximum number of active volumes that can run per node in an Ondat cluster:

| **Kernel Version** | **Maximum Number Of Active Volumes Per Node Allowed** |
| ------------------ | ----------------------------------------------------- |
| `3.x.x`            | `256`                                                 |
| `4.x.x`            | `4096`                                                |
| `5.x.x`            | `4096`                                                |
| `6.x.x`            | `4096`                                                |

### Linux Asynchronous I/O (AIO)

- When the Ondat Data plane component is operational, Ondat leverages [Linux Asynchronous I/O (AIO)](https://developer.ibm.com/articles/l-async/) contexts to initiate a number of I/O requests without having to block or wait for any to complete to process the next task - thus allowing you to boost performance for applications that are able to simultaneously overlap processing and I/O.
- The Linux kernel uses the [`/proc/sys/fs/aio-max-nr`](https://www.kernel.org/doc/Documentation/sysctl/fs.txt) virtual file to set the value of the maximum number of *allowable* AIO concurrent requests. The `/proc/sys/fs/aio-nr` virtual file also provides information on the current number of asynchronous requests on the node.
- Ondat requires `4` AIO contexts per deployed volume, whether it is a master or replica volume.
  - Trying to provision additional volumes once the `aio-nr` value reaches the `aio-max-nr`, will cause a `io_setup` system call to fail and return a [`EAGAIN` error](https://www.kernel.org/doc/Documentation/sysctl/fs.txt), meaning that the resource becomes temporarily unavailable.
- Therefore, if your nodes `aio-max-nr` kernel parameter value is less than `1048576`, a strong recommendation will be to set a new value in your `/etc/sysctl.conf` or through a custom configuration file in `/etc/sysctl.d/` to increase the number of AIO contexts that can be requested:

| Kernel Parameter | Value     |
| ---------------- | --------- |
| `fs.aio-max-nr`  | `1048576` |

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

- Below is the following list of current Linux distributions (non-EOL) that are supported by Ondat:

| **Name**                                                                                                    | **Linux Distribution Support Notes**                                                                             |
| ----------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| [`Amazon Linux 2022 (AL2022)`](https://aws.amazon.com/linux/amazon-linux-2022/)                             | Yes - (Available from the **11th of November 2022** release on kernel `5.4.219-126.411.amzn2.x86_64` or greater) |
| [`Bottlerocket`](https://aws.amazon.com/bottlerocket/)                                                      | Yes - ([Snapshots feature](https://docs.ondat.io/docs/concepts/snapshots/) is currently unavailable)             |
| [`CentOS`](https://www.centos.org/)                                                                         | Yes                                                                                                              |
| [`Debian`](https://www.debian.org/)                                                                         | Yes                                                                                                              |
| [`Fedora`](https://getfedora.org/)                                                                          | Yes                                                                                                              |
| [`Google Container-Optimized OS (COS)`](https://cloud.google.com/container-optimized-os/)                   | Yes - (The required kernel modules are available, but the distribution has not undergone exhaustive testing yet) |
| [`openSUSE`](https://www.opensuse.org/)                                                                     | Yes                                                                                                              |
| [`RedHat Enterprise Linux (RHEL)`](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux) | Yes                                                                                                              |
| [`SUSE Linux Enterprise Server (SLES)`](https://www.suse.com/products/server/)                              | Yes                                                                                                              |
| [`Ubuntu`](https://ubuntu.com/)                                                                             | Yes                                                                                                              |

> 💡 As a general rule of thumb, Ondat is agnostic and will run on any Linux distribution as long as the [required kernel modules prerequisites](#required-kernel-modules) are available and can be successfully loaded. In most modern Linux distributions, the key kernel modules are distributed as part of the default Linux kernel packages. In some older distributions, the kernel modules were part of the kernel `extras` package that needed to be installed separately.

> 💡 If you need help with a specific issue with one of the listed distributions we support, [raise an issue up on GitHub](https://github.com/ondat/documentation/issues) or reach out to us through our [Community Slack](https://slack.storageos.com/).

## Container Orchestrators

### Supported Kubernetes Distributions

- Ondat will run on Kubernetes `v1.2x` or OpenShift `v4.x` channels, with an (`n - 4`) release support, where `n` is the latest stable Kubernetes version release available.

> 💡 Review the official [Kubernetes releases](https://kubernetes.io/releases/) page for more information on the versions available.

| **Name**                                                                                                                       | **Supported Versions**     |
| ------------------------------------------------------------------------------------------------------------------------------ | -------------------------- |
| [`Kubernetes`](https://docs.ondat.io/docs/install/kubernetes/)                                                                 | Yes - (`n - 4`)            |
| [`Amazon Elastic Kubernetes Service (EKS)`](https://docs.ondat.io/docs/install/aws/)                                           | Yes - (`n - 4`)            |
| [`Amazon EKS Anywhere`](https://docs.ondat.io/docs/install/aws/)                                                               | Yes - (`n - 4`)            |
| [`Microsoft Azure Kubernetes Service (AKS)`](https://docs.ondat.io/docs/install/azure/)                                        | Yes - (`n - 4`)            |
| [`DigitalOcean Kubernetes (DOKS)`](https://docs.ondat.io/docs/install/digitalocean/)                                           | Yes - (`n - 4`)            |
| [`Google Kubernetes Engine (GKE)`](https://docs.ondat.io/docs/install/gcp/)                                                    | Yes - (`n - 4`)            |
| [`Google Anthos`](https://docs.ondat.io/docs/install/gcp/)                                                                     | Yes - (`n - 4`)            |
| [`Red Hat OpenShift Container Platform (OCP)`](https://docs.ondat.io/docs/install/openshift/openshift-container-platform-ocp/) | Yes - (`n - 4`)            |
| [`MicroK8s`](https://docs.ondat.io/docs/install/canonical/)                                                                    | Yes - (`v1.26` or greater) |
| [`Rancher Kubernetes Engine (RKE)`](https://docs.ondat.io/docs/install/rancher/)                                               | Yes - (`n - 4`)            |
| [`Rancher Kubernetes Engine 2 (RKE2)`](https://docs.ondat.io/docs/install/rancher/)                                            | Yes - (`n - 4`)            |

### Container Runtimes

| **Name**                                    | **Supported Versions**     |
| ------------------------------------------- | -------------------------- |
| [`containerd`](https://containerd.io/)      | Yes                        |
| [`cri-o`](https://cri-o.io/)                | Yes                        |
| [`docker`](https://docs.docker.com/engine/) | Yes - (`v1.10` or greater) |

### Mount Propagation

- It is required that [mount propagation](https://kubernetes-csi.github.io/docs/deploying.html#enabling-mount-propagation) is enabled for the container orchestrator where Ondat will be deployed in. Mount propagation is enabled by default in the newer release versions of Kubernetes and OpenShift.

| **Name**     | **Enabled Versions** |
| ------------ | -------------------- |
| `Kubernetes` | `1.10` or greater    |
| `OpenShift`  | `3.11` or greater    |

> 💡 If your container orchestrator has mount propagation disabled, and you are looking for guidance on how to enable it, review the [Kubernetes](https://kubernetes.io/docs/concepts/storage/volumes/#mount-propagation) and [OpenShift](https://docs.openshift.com/container-platform/3.11/install_config/storage_examples/mount_propagation.html) documentation on mount propagation for more information.

### Process ID (PID) Limits

- Ondat pods that are running in a Kubernetes or OpenShift cluster are part of a PID `cgroup` that may limit the maximum number of PIDs that all containers in the PID `cgroup` slice can spawn.
- As the Linux kernel assigns a PID to processes and [Light-Weight Processes (LWPs)](https://en.wikipedia.org/wiki/Light-weight_process), a low PID limit can be easily reached without breaching any other resource limits, which could then potentially cause instability issues as Ondat won’t be able to spawn new processes.
- Depending on the container orchestrator you are using, the PID limit is set by the distribution or the container runtime being used. Therefore, ensure that the [PID limit](https://kubernetes.io/docs/concepts/policy/pid-limiting/#pod-pid-limits/) is set to at least `32768` for Ondat pods in your cluster:

| Kubelet Parameter                  | Value   |
| ---------------------------------- | ------- |
| `--pod-max-pids` or `PodPidsLimit` | `32768` |

> 💡 To check if the PID limit of the PID `cgroup` slice that the Ondat pods runs in is set to at least `32768`, Ondat  will run an [init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) which conducts preflight checks to ensure that the correct limit is set. If your cluster defaults to a low PID limit, it is recommended to follow your distribution's documentation on how to configure and set a higher limit. Review the [Kubernetes - Configure Pod PID Limits](https://kubernetes.io/docs/concepts/policy/pid-limiting/#pod-pid-limits) and [OpenShift - Creating a ContainerRuntimeConfig CR to Edit CRI-O Parameters](https://docs.openshift.com/container-platform/latest/post_installation_configuration/machine-configuration-tasks.html#create-a-containerruntimeconfig_post-install-machine-configuration-tasks) documentation for guidance.

> ⚠️ OpenShift uses [CRI-O](https://cri-o.io/) as the container runtime, which has a PID limit that defaults to `1024` as demonstrated above. It is strongly recommended that you raise the PID limit to at least `32768` to avoid instability issues.

## Networking

### Firewall Rules

For Ondat components to be able to successfully communicate with each other in a cluster, ensure that you add the following firewall rules or web proxy exceptions between nodes.
