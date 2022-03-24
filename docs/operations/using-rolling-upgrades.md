---
linkTitle: Using Rolling Upgrades Feature 
---

# Overview
This guide will demonstrate how to enable the orchestrator's rolling upgrades using the [Upgrade Guard](/docs/concepts/rolling-upgrades/#upgrade-guard) and [Node Manager](/docs/concepts/rolling-upgrades/#upgrade-guard). This feature helps to prevent your persistent storage volumes from becoming unhealthy during an orchestrator update.

# Prerequisites
> ⚠️ Make sure you have met the requirements of [configuring a Pod Disruption Budget (PDB)](https://kubernetes.io/docs/tasks/run-application/configure-pdb/).

> ⚠️ For Openshift: The PDB feature is only stable in kubernetes v1.21+ and Openshift v4.8+.

> ⚠️ If your volume does not have any replicas, the rolling upgrades feature will be disabled by default.

# Procedure
## Step 1 - Enable Node Manager and Upgrade Guard
* Add the following lines to the StorageOSCluster spec:

```
 nodeManagerFeatures:
   upgradeGuard: ""
```

>You can also use this one-liner to do that:
` kubectl get storageoscluster -n storageos storageoscluster -o yaml | sed -e 's|^spec:$|spec:\n  nodeManagerFeatures:\n    upgradeGuard: ""|' | kubectl apply -f - `

Questions:
* What do we see when we turn it on ?
* What do users need to do next to start doing an upgrade?
* Should we just combine the two docs of explaining what is an upgrade guard vs node guard?
* The rolling upgrade feature will be disabled by default, what does that mean ? Does it mean a replica is needed to use this?