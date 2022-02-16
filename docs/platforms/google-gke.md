---
title: "Google GKE"
linkTitle: Google GKE
---

StorageOS is fully compatible with GKE when using the Ubuntu images. To
install StorageOS on Google GKE, follow our Kubernetes [installation instructions](/docs/install/kubernetes) page.

For StorageOS to work normally it is __required to use the Ubuntu images__ for
the Google GKE node pools. The default container image does not fulfil the system
requirements because of the lack of the TCMU kernel modules.

For more details about the OS Distributions check the [System Configuration](/docs/prerequisites/systemconfiguration) page.

## Google Anthos

Ondat is compatible with Google Anthos. However it is required that the
Linux image distribution used fulfils the [System Configuration](/docs/prerequisites/systemconfiguration) prerequisites.

Once a Kubernetes cluster is provisioned, StorageOS can be installed following
the [instructions](/docs/install/kubernetes) page.
