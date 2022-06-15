---
title: "OpenShift"
linkTitle: OpenShift
---

Ondat V2 supports Openshift v4.0+.

Red Hat OpenShift and Ondat communicate with each other to perform actions such as
creation, deletion and mounting of volumes through CSI. The CSI container
running in the Ondat Daemonset creates a Linux socket that allows the
communication between Red Hat OpenShift and Ondat.

## Installation

To install Ondat on Red Hat OpenShift, follow our [installation instructions](/docs/install/openshift) page.

> ⚠️ Red Hat Openshift 4 uses the CRI-O container runtime that sets a default PID
> limit of 1024. Ondat recommends that the limit be raised to 32768.
> Please see our [prerequisites](/docs/prerequisites/pidlimits) for more details.

## Red Hat OpenShift Upgrades

Red Hat OpenShift provides an upgrade operator that automates the process of orchestrator version changes.

> ⚠️ Use the [rolling upgrade feature](/docs/operations/using-rolling-upgrades) to protect your cluster from major incidents during an upgrade. Please contact Ondat support for further advice if required.

> ⚠️ Red Hat OpenShift requires the internal registry to be available during the upgrade, however Ondat volumes may not be available. Therefore using Ondat for the internal registry is **not** recommended.

## CSI (Container Storage Interface)

CSI is the standard that enables storage drivers to release on their own
schedule. This allows storage vendors to upgrade, update, and enhance their
drivers without the need to update Kubernetes source code, or follow Kubernetes
release cycles. Ondat v2 uses CSI to implement communication with the
Red Hat OpenShift controlplane.

## Ondat PersistentVolumeClaims

The user can provide standard PVC definitions and Ondat will dynamically
provision them. Ondat presents volumes to containers with standard POSIX
mount targets. This enables the Kubelet to mount Ondat volumes using
standard linux device files. Checkout [device presentation](/docs/prerequisites/systemconfiguration) for more details.
