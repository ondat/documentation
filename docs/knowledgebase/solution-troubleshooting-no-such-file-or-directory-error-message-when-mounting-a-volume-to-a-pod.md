---
title: "Solution - Troubleshooting 'no such file or directory' Error Message When Mounting A Volume To A Pod"
linkTitle: "Solution - Troubleshooting 'no such file or directory' Error Message When Mounting A Volume To A Pod"
---

## Issue

You are experiencing an issue where you get the following error message >> `no such file or directory` being displayed in the `Events:` section of a pod - causing it to be stuck in a `Pending` state. Below is an example output of the error message upon describing the affected pod.

```bash
# Describe the affected pod to get more information from the "Events:" section.
kubectl describe pod affected-pod-name

# Truncated output.
Events:
  (...)
  Normal   Scheduled         11s                default-scheduler  Successfully assigned default/d1 to node3
  Warning  FailedMount       4s (x4 over 9s)    kubelet, node3     MountVolume.SetUp failed for volume "pvc-f2a49198-c00c-11e8-ba01-0800278dc04d" : stat /var/lib/storageos/volumes/d9df3549-26c0-4cfc-62b4-724b443069a1: no such file or directory
```

## Root Cause

There are two root causes on why this issue may arise:
1. The Ondat  `DEVICE_DIR`  location is wrongly configured when using  [`kubelet`](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/) as a container.
1. Mount Propagation is not enabled.

## Resolution

- **Option 1 - Correctly Configure The `DeviceDir`/`SharedDir` Path**
  - Some Kubernetes distributions such as Rancher or different deployments of OpenShift may deploy the [`kubelet`](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/) as a container. Because of this, the device files that Ondat creates to mount into the containers need to be visible to the `kubelet`. Ondat can be configured to share the device directory. Modern Kubernetes and OpenShift deployments use the Container Storage Interface (CSI) to handle the complexity internally.
  - To resolve this issue, check and confirm that the `SharedDir` key-value pair in the Ondat Custom Resource is not blank. If it is blank, edit the Ondat Custom Resource to point the `SharedDir` key to >> `/var/lib/kubelet/plugins/kubernetes.io~storageos` as demonstrated below.

	```bash
	# Get more information about the Ondat Custom Resource.
	kubectl --namespace storageos describe storageosclusters.storageos.com | grep "Shared Dir"

	  Shared Dir:            # This key-value pair should have a defined path.
	```

	```bash
	# Edit the Custom Resource and ensure that the SharedDir key points to "/var/lib/kubelet/plugins/kubernetes.io~storageos"
	kubectl --namespace storageos edit storageosclusters.storageos.com


	# Truncated output.
	spec:
	  sharedDir: '/var/lib/kubelet/plugins/kubernetes.io~storageos'        # This is required if the "kubelet" is running as a container in your cluster.
	# Truncated output.
	```

💡 For more information on how to configure the Ondat Custom Resource, review the [Ondat Operator Examples](/docs/reference/operator/examples/) page.

- **Option 2 - Enable Mouth Propagation**
> 💡 The guidance below only applies if **Option 1** has been configured correctly.
  - For older versions of Kubernetes & OpenShift, users need to enable [mount propagation](https://kubernetes.io/docs/concepts/storage/volumes/#mount-propagation), as it is not enabled by default. Most Kubernetes distributions allow `MountPropagation` to be enabled using [Feature Gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/). Rancher, specifically, needs to enable it in the “View in API” section of your cluster. You need to edit the section `rancherKubernetesEngineConfig` to enable the `kubelet` feature gate. 
  - **If your cluster is NOT using the `kubelet` as a container** - `ssh` into one of the nodes and check if >> `/var/lib/storageos/volumes` is empty. 
  - If the directory is empty, `exec` into any of the Ondat daemonset pods and check the same directory to further verify if the directory inside the container and the device files are visible. If they are visible in the container, check ensure that mount propagation is enabled.

	```bash
	# ssh into one of the nodes to check if the directory and device files exist (the directory should not be empty).
	ls /var/lib/storageos/volumes/

	# exec into one any of the Ondat daemonset pods to check if the directory and directory and device files exist.
	kubectl --namespace storageos exec storageos-node-mvbtw --container storageos -- ls -l /var/lib/storageos/volumes

	# Output.
	bst-196004
	d529b340-0189-15c7-f8f3-33bfc4cf03fa
	ff537c5b-e295-e518-a340-0b6308b69f74
	```
  - **If your cluster is using the `kubelet` as a container** - `ssh` into one of the nodes and check if >> `/var/lib/kubelet/plugins/kubernetes.io~storageos/devices` is empty. 
  - If the directory is empty, `exec` into any of the Ondat daemonset pods and check the same directory to further verify if the directory inside the container and the device files are visible. If they are visible in the container, check and ensure that mount propagation is enabled.

	```bash
	# ssh into one of the nodes to check if the directory and device files exist (the directory should not be empty).
	ls /var/lib/kubelet/plugins/kubernetes.io~storageos/devices

	# exec into one any of the Ondat daemonset pods to check if the directory and directory and device files exist.
	kubectl --namespace storageos exec storageos-node-mvbtw --container storageos -- ls -l /var/lib/kubelet/plugins/kubernetes.io~storageos/devices

	# Output.
	bst-196004
	d529b340-0189-15c7-f8f3-33bfc4cf03fa
	ff537c5b-e295-e518-a340-0b6308b69f74
	```

## References

- [Kubelet - Kubernetes Reference Documentation](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/).
- [Volumes - Mount Propagation - Kubernetes Documentation](https://kubernetes.io/docs/concepts/storage/volumes/#mount-propagation).
- [Feature Gates - Kubernetes Documentation](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/).
