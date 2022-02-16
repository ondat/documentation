---
title: "Amazon EKS"
linkTitle: AWS EKS
---

Ondat is fully compatible with Amazon EKS. To install Ondat on EKS,
follow our Kubernetes [installation instructions](/docs/install/kubernetes) page.

An Amazon EKS deployment of Kubernetes uses Amazon Linux by default with an optimized
kernel. As the requisite kernel modules are not available for Ondat to use
TCMU, FUSE will be used as a fallback. Using FUSE instead of TCMU has
performance implications.

For more details about the OS Distributions, see the [System Configuration](/docs/prerequisites/systemconfiguration)
page.
