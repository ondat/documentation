---
title: "Kubevirt"
linkTitle: Kubevirt
---

![image](/images/docs/explore/kubevirt.png)

[Kubevirt](https://kubevirt.io) is a CNCF sandbox project that allows the
running of virtual machines (VMs) in Kubernetes pods.

Deploying Kubevirt using Ondat offers multiple benefits. Kubevirt can spin
up VMs as Kubernetes pods, using images on Ondat persistent volumes. Doing
this allows the VM data to persist through restarts and rescheduling. Using
Ondat [volume
replicas](/docs/concepts/replication) also allows for
failure of nodes holding the PersistentVolume without interrupting the VM
running off the PersistentVolume. [Containerized Data Importer
(CDI)](https://github.com/kubevirt/containerized-data-importer) can also be
used to prepare Ondat volumes with disk images in an automated fashion.
Simply by declaring that a `VirtualMachine` will use a DataVolume and providing
the disk image URL, an Ondat volume can be dynamically provisioned and
automatically prepared with the disk image.

This usecase will guide you through installing KubeVirt and CDI on your
Kubernetes cluster, and create a VM. By the end of the guide you'll be able to
launch a shell inside the KubeVirt VM that's running as a Kubernetes pod.

Before you start, ensure you have Ondat installed and ready on a Kubernetes
cluster. [See our guide on how to install Ondat on Kubernetes for more
information](/docs/install/kubernetes).

## Prerequisites

Ensure you have met the Kubevirt prerequisites, see the [
Kubevirt installation instructions
](https://kubevirt.io/user-guide/operations/installation/) for
more information.

As part of this installation it is assumed that you are running a Kubernetes
cluster on VMs. As such nested virtualization or hardware emulation need to be
enabled.

## Deploying KubeVirt on Kubernetes

> 💡 For ease of installation we have enabled hardware emulation. If your VMs
> support nested virtualization then edit the Kubevirt ConfigMap
> `./kubevirt-install/10-cm.yaml`, removing the line `debug.useEmulation:
> "true"`.

1. In order to deploy Kubevirt you just need to clone this repository and use
   kubectl to create the Kubernetes objects.

   ```bash
   git clone https://github.com/storageos/use-cases.git storageos-usecases
   cd storageos-usecases/kubevirt
   kubectl create -f ./kubevirt-install
   ```

1. Check that the Kubevirt pods are running.

   ```bash
   $ kubectl get pods -w -n kubevirt
      NAME                               READY   STATUS    RESTARTS   AGE
      virt-api-57546d479b-p26d4          1/1     Running   0          1m
      virt-api-57546d479b-zs5dw          1/1     Running   0          1m
      virt-controller-56b5498854-7xsfz   1/1     Running   1          1m
      virt-controller-56b5498854-bz559   1/1     Running   1          1m
      virt-handler-6z4kq                 1/1     Running   0          1m
      virt-handler-7szhl                 1/1     Running   0          1m
      virt-handler-jmm6w                 1/1     Running   0          1m
      virt-operator-79c9bdd859-8xq98     1/1     Running   0          1m
      virt-operator-79c9bdd859-kfjz6     1/1     Running   0          1m
   ```

1. Once Kubevirt is running install CDI.

   ```bash
   kubectl create -f ./cdi
   ```

1. Check that the CDI pods are running correctly.

   ```bash
   $ kubectl get pods -n cdi
   NAME                              READY   STATUS    RESTARTS   AGE
   cdi-apiserver-8668f888df-s6pp4    1/1     Running   0          1m
   cdi-deployment-5cf794896b-whh4j   1/1     Running   0          1m
   cdi-operator-5887f96c-dz2hg       1/1     Running   0          1m
   cdi-uploadproxy-97fbbfcbf-6f9xs   1/1     Running   0          1m
   ```

1. Now that CDI and Kubevirt are running, VMs can be created. In this example
   VMs running [Cirros](https://launchpad.net/cirros/), a small and lightweight
   OS, will be created.  The `vm-cirros.yaml` manifest creates a
   `VirtualMachine` that uses a DataVolume. This means that CDI will create a
   Ondat backed PVC and download the image that the
   `VirtualMachineInstance` (VMI) will boot from onto the PVC.

   ```bash
   kubectl create -f ./vm-cirros.yaml
   ```

1. Check that the `VMI` is running. Note that the
   `VMI` will only be created after CDI has downloaded the
   Cirros disk image onto an Ondat persistent volume so depending on your
   connection speed this may take some time.

   ```bash
   $ kubectl get vmi
   NAME     AGE   PHASE     IP            NODENAME
   cirros   1m   Running   10.244.2.12   ip-10-1-10-154.storageos.net
   $ kubectl get pods
   NAME                         READY   STATUS    RESTARTS   AGE
   virt-launcher-cirros-drqhr   1/1     Running   0          1m
   ```

1. Connect to the VM console.

    This example uses the [virtctl
   kubectl](https://kubevirt.io/quickstart_minikube/#install-virtctl) plugin in
   order to connect to the VMs console. The escape sequence `^]` is `ctrl + ]`

   ```bash
   $ kubectl virt console cirros
   Successfully connected to cirros console. The escape sequence is ^]
   login as 'cirros' user. default password: 'gocubsgo'. use 'sudo' for root.
   cirros login: cirros
   Password:
   $
   ```

## Cloning Volumes

CDI allows for images to be cloned using a DataVolume manifest. Verify that the
cirros pvc, created as part of the vm-cirros.yaml file, exists before
attempting to clone the volume.

> ⚠️ Ensure that the `VMI` is stopped before continuing!

1. Verify that the VMI is stopped before continuing, and that the cirros pvc,
   created as part of the vm-cirros.yaml file, exists before attempting to
   clone the volume.

   ```bash
   $ kubectl get pvc
   NAME    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
   cirros  Bound    pvc-f4833060-5a77-420c-927e-6bc518d9df3c   12Gi       RWO            storageos       1m
   ```

1. Once the PVC's existence is confirmed then create a new DataVolume that uses the cirros PVC as its source.

   ```bash
   kubectl create -f ./cloned.yaml
   ```

1. Watch as the CDI pods are created.

   ```bash
   kubectl get pods -w
   ```

   You'll see that a `cdi-upload-cloned-datavolume` pod is created and then a
   cdi-clone-source pod is created. The cdi-source pod mounts the original
   cirros volume and sends the contents of the volume to the cdi-upload pod.
   The cdi-upload pod creates and mounts a new PVC and writes the contents of
   the original volume to it.
