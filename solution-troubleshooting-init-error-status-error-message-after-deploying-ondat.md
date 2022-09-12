---
title: "Solution - Troubleshooting 'Init:Error' Status Error Message After Deploying Ondat"
linkTitle: "Solution - Troubleshooting 'Init:Error' Status Error Message After Deploying Ondat"
---

## Issue

When attempting to deploy Ondat into an OpenShift or Kubernetes cluster, you notice that the Ondat daemonset set pods are stuck in a `Init:Err` state. Below is an example of the error message being reported under the `STATUS` column.

```bash
# Get the status of the pods in the "storageos" namespace.
kubectl get pods --namespace storageos

NAME                                                 READY   STATUS    RESTARTS   AGE
# Truncated output...
storageos-node-8fhf6                                 0/3     Init:Err  0          6s
storageos-node-8z77g                                 0/3     Init:Err  0          6s
storageos-node-pzvp7                                 0/3     Init:Err  0          6s
storageos-node-qbjbr                                 0/3     Init:Err  0          6s
storageos-node-vkj92                                 0/3     Init:Err  0          6s
# Truncated output...
```

## Root Cause

The root cause of this issue is due to missing [Linux-IO (LIO) related kernel modules](https://en.wikipedia.org/wiki/LIO_%28SCSI_target%29) on worker nodes that are required for Ondat to successfully start up and run.

- The Ondat daemonset will attempt to load the required kernel modules onto the worker nodes. If Ondat is unsuccessful in loading the kernel modules, an `Init:Err` error will be returned and fail Ondat from starting up without the required kernel modules.

## Resolution

1. Check and ensure that the logs of the `init` container report any kernel modules that Ondat tried to load:

```bash
# Chec the logs of the "init" container to list the missing kernel modules required for Ondat to run.
kubectl --namespace storageos logs storageos-node-8z77g --container init

# Truncated output...
Checking configfs
configfs mounted on sys/kernel/config
Module target_core_mod is not running
executing modprobe -b target_core_mod
Module tcm_loop is not running
executing modprobe -b tcm_loop
modprobe: FATAL: Module tcm_loop not found.             # "tcm_loop" kernel module is missing.
```

1. If the logs report missing kernel modules that are required for Ondat to run, a recommendation would be to check and ensure that your node's distribution makes the kernel module available for use. End users can also install `linux-image-extra-$(uname -r)` package for your distribution which contains extra kernel modules that may have been left out of the base kernel package.
    - For more information on the required kernel modules for Ondat, review the [Ondat Prerequisites](/docs/prerequisites/systemconfiguration) page.

1. Once the kernel modules have been successfully installed on the nodes, restart the Ondat daemonset pods by deleting the pods and let Kubernetes recreate the pods, which will detect the new system changes on the nodes.
