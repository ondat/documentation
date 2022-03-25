---
title: "Install"
linkTitle: "Install"
weight: 400
description: >
  Ondat is platform agnostic, however, there are details on different
  providers and Kubernetes distributions to take in consideration. Follow the instructions to Install, Provision or Troubleshoot according to your providers.
---

# Kubernetes with Ondat

Ondat integrates transparently with Kubernetes and different distributions
such as OpenShift, Rancher, EKS, AKS, GKE, etc. The user can provide standard
PVC definitions and Ondat will dynamically provision matching volumes.
Ondat presents volumes to containers with standard POSIX mount targets.
This enables the Kubelet to mount Ondat volumes using standard linux device
files. Checkout [device presentation](/docs/concepts/volumes) for more details.

Kubernetes and Ondat communicate with each other to perform actions such as
creation, deletion or mounting of volumes. The CSI (Container Storage
Interface) driver is the standard method of communication. Using CSI,
Kubernetes and Ondat communicate over a Unix domain socket.

# CSI (Container Storage Interface)

CSI is the standard method of communication that enables storage drivers for
Kubernetes to release on their own schedule. The CSI standard allows storage
vendors to upgrade, update, and enhance their drivers without the need to
update Kubernetes source code, or follow Kubernetes release cycles.

CSI was released GA from Kubernetes 1.13. Ondat v2 only supports the use of
CSI as a storage driver. In addition, the Ondat Cluster Operator handles
the configuration of the CSI driver and its complexity by detecting the version
of the Kubernetes installed.

Check out the status of the CSI release cycle in relation with Kubernetes in
the [CSI project](https://kubernetes-csi.github.io/docs/) page.

CSI communication is fully supported by Ondat if the cluster is deployed
with any [supported Linux Distribution](/docs/prerequisites/systemconfiguration#distribution-specifics).

# Kubernetes Upgrades on Managed Services

Managed services that support in place upgrades are fully supported. Upgrading Kubernetes using green/blue deployments requires you to turn on the rolling upgrade feature to protect your cluster from major issues.

Follow the instruction [here](docs/operations/using-rolling-upgrades.md). Please contact Ondat support for further advice if required.
