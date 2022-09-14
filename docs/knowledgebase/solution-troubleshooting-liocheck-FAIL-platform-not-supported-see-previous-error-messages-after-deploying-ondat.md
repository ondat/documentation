---
title: "Solution - Troubleshooting 'liocheck: FAIL (platform not supported, see previous error messages)' Error Message After Deploying Ondat"
linkTitle: "Solution - Troubleshooting 'liocheck: FAIL (platform not supported, see previous error messages)' Error Message After Deploying Ondat"
---

## Issue

When attempting to deploy Ondat into an OpenShift or Kubernetes cluster, you notice that the Ondat daemonset set pods are unable to start. Upon reviewing the logs of one of the Ondat daemonset pods, there is `WARN` and `FATAL` log entry that was reported:

```bash
# Truncated output.
category=lio level=WARN   msg="Runtime error checking stage 'Start TCMU and create device': /sys/module/target_core_user is missing, is kernel configfs present and target_core_user loaded?"
category=lio level=FATAL  msg="liocheck: FAIL (platform not supported, see previous error messages)"
```

## Root Cause

The root cause of this issue is due to one or more of the required [Linux-IO (LIO) related kernel modules](https://en.wikipedia.org/wiki/LIO_%28SCSI_target%29) have not been successfully loaded onto the worker nodes where the Ondat daemonset will run.

## Resolution

1. Ensure that the following kernel modules are loaded onto the worker nodes where an Ondat daemonset pod will run.

 ```bash
 # Check to see if you can successfully find and list the kernel modules that are required for Ondat to run.
 lsmod | egrep "^tcm_loop|^target_core_mod|^target_core_user|^configfs|^uio"
 ```

1. End users can install the `linux-image-extra-$(uname -r)` package for your distribution which contains extra kernel modules that may have been left out of the base kernel package. End user can also use `modprobe` to load the required kernel modules:

 ```bash
 # Ensure that "kmod" is installed.
 sudo apt install kmod               # Debian based distributions.
 sudo dnf install kmod               # Red Hat based distributions.

 # Use "modprobe" to load the kernel modules below on the worker nodes were Ondat will run.
 modprobe --all target_core_mod tcm_loop configfs target_core_user uio
 ```

 > 💡 For more information on the required kernel modules for Ondat, review the [Ondat Prerequisites](https://github.com/ondat/documentation/blob/kb-ondat-init-error-after-deployment/docs/prerequisites/systemconfiguration) page.

1. Once the kernel modules have been successfully installed on the nodes, restart the Ondat daemonset pods by deleting the pods and let Kubernetes recreate the pods, which will detect the new system changes on the nodes.
