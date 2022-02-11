---
title: "Kubernetes"
linkTitle: "Kubernetes"
weight: 1
---

> ⚠️ Make sure the
> [prerequisites for Ondat](/docs/prerequisites/_index) are
> satisfied before proceeding.

> ⚠️ Make sure to add a Ondat licence after installing.

> 💡 Any Kubernetes managed service such as EKS, AKS, GKE, DO or DockerEE
> platform can use the following Kubernetes guide to install Ondat.

> 💡 Ondat supports the five most recent Kubernetes releases, at minimum.

> Ondat also has an official Helm chart, see [the charts repository](https://github.com/ondat/charts/tree/main/charts/ondat-operator) for instructions.

&nbsp;

## Install ondat on kubernetes 1.22

### Install the storageos kubectl plugin

```
curl -sSLo kubectl-storageos.tar.gz \
    https://github.com/storageos/kubectl-storageos/releases/download/v1.0.0/kubectl-storageos_1.1.0_linux_amd64.tar.gz \
    && tar -xf kubectl-storageos.tar.gz \
    && chmod +x kubectl-storageos \
    && sudo mv kubectl-storageos /usr/local/bin/ \
    && rm kubectl-storageos.tar.gz
```

> 💡 You can find binaries for different architectures and systems in [kubectl
> plugin](https://github.com/storageos/kubectl-storageos/releases).

### Install Ondat

```bash
kubectl storageos install \
    --etcd-endpoints 'storageos-etcd-client.storageos-etcd:2379' \
    --admin-username "myuser" \
    --admin-password "my-password"
```

> 💡 Define the etcd endpoints as a comma delimited list, e.g. 10.42.3.10:2379,10.42.1.8:2379,10.42.2.8:2379

> 💡 If the etcd endpoints are not defined, the plugin will prompt you and
> request the endpoints.

### Verify Ondat installation

Ondat installs all its components in the `storageos` namespace.

```bash
$ kubectl -n storageos get pod -w
NAME                                     READY   STATUS    RESTARTS   AGE
storageos-api-manager-65f5c9dbdf-59p2j   1/1     Running   0          36s
storageos-api-manager-65f5c9dbdf-nhxg2   1/1     Running   0          36s
storageos-csi-helper-65dc8ff9d8-ddsh9    3/3     Running   0          36s
storageos-node-4njd4                     3/3     Running   0          55s
storageos-node-5qnl7                     3/3     Running   0          56s
storageos-node-7xc4s                     3/3     Running   0          52s
storageos-node-bkzkx                     3/3     Running   0          58s
storageos-node-gwp52                     3/3     Running   0          62s
storageos-node-zqkk7                     3/3     Running   0          62s
storageos-operator-8f7c946f8-npj7l       2/2     Running   0          64s
storageos-scheduler-86b979c6df-wndj4     1/1     Running   0          64s
```

> Wait until all the pods are ready. It usually takes ~60 seconds to complete

### License cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our
> personal license is free, and supports up to 1TiB of provisioned storage.

To obtain a license, follow the instructions on our [licensing operations](/docs//operations/licensing) page.

## Install Ondat on Kubernetes 1.21

### Install the storageos kubectl plugin

```
curl -sSLo kubectl-storageos.tar.gz \
    https://github.com/storageos/kubectl-storageos/releases/download/v1.0.0/kubectl-storageos_1.0.0_linux_amd64.tar.gz \
    && tar -xf kubectl-storageos.tar.gz \
    && chmod +x kubectl-storageos \
    && sudo mv kubectl-storageos /usr/local/bin/ \
    && rm kubectl-storageos.tar.gz
```

> 💡 You can find binaries for different architectures and systems in [kubectl
> plugin](https://github.com/storageos/kubectl-storageos/releases).

### Install Ondat

```bash
kubectl storageos install \
    --etcd-endpoints 'storageos-etcd-client.storageos-etcd:2379' \
    --admin-username "myuser" \
    --admin-password "my-password"
```

> 💡 Define the etcd endpoints as a comma delimited list, e.g. 10.42.3.10:2379,10.42.1.8:2379,10.42.2.8:2379

> 💡 If the etcd endpoints are not defined, the plugin will prompt you and
> request the endpoints.

### Verify Ondat installation

Ondat installs all its components in the `storageos` namespace.

```bash
$ kubectl -n storageos get pod -w
NAME                                     READY   STATUS    RESTARTS   AGE
storageos-api-manager-65f5c9dbdf-59p2j   1/1     Running   0          36s
storageos-api-manager-65f5c9dbdf-nhxg2   1/1     Running   0          36s
storageos-csi-helper-65dc8ff9d8-ddsh9    3/3     Running   0          36s
storageos-node-4njd4                     3/3     Running   0          55s
storageos-node-5qnl7                     3/3     Running   0          56s
storageos-node-7xc4s                     3/3     Running   0          52s
storageos-node-bkzkx                     3/3     Running   0          58s
storageos-node-gwp52                     3/3     Running   0          62s
storageos-node-zqkk7                     3/3     Running   0          62s
storageos-operator-8f7c946f8-npj7l       2/2     Running   0          64s
storageos-scheduler-86b979c6df-wndj4     1/1     Running   0          64s
```

> Wait until all the pods are ready. It usually takes ~60 seconds to complete

### License cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our
> personal license is free, and supports up to 1TiB of provisioned storage.

To obtain a license, follow the instructions on our [licensing operations](/docs//operations/licensing) page.

## Install Ondat on Kubernetes 1.20

### Install the storageos kubectl plugin

```
curl -sSLo kubectl-storageos.tar.gz \
    https://github.com/storageos/kubectl-storageos/releases/download/v1.0.0/kubectl-storageos_1.0.0_linux_amd64.tar.gz \
    && tar -xf kubectl-storageos.tar.gz \
    && chmod +x kubectl-storageos \
    && sudo mv kubectl-storageos /usr/local/bin/ \
    && rm kubectl-storageos.tar.gz
```

> 💡 You can find binaries for different architectures and systems in [kubectl
> plugin](https://github.com/storageos/kubectl-storageos/releases).

### Install Ondat

```bash
kubectl storageos install \
    --etcd-endpoints 'storageos-etcd-client.storageos-etcd:2379' \
    --admin-username "myuser" \
    --admin-password "my-password"
```

> 💡 Define the etcd endpoints as a comma delimited list, e.g. 10.42.3.10:2379,10.42.1.8:2379,10.42.2.8:2379

> 💡 If the etcd endpoints are not defined, the plugin will prompt you and
> request the endpoints.

### Verify Ondat installation

Ondat installs all its components in the `storageos` namespace.

```bash
$ kubectl -n storageos get pod -w
NAME                                     READY   STATUS    RESTARTS   AGE
storageos-api-manager-65f5c9dbdf-59p2j   1/1     Running   0          36s
storageos-api-manager-65f5c9dbdf-nhxg2   1/1     Running   0          36s
storageos-csi-helper-65dc8ff9d8-ddsh9    3/3     Running   0          36s
storageos-node-4njd4                     3/3     Running   0          55s
storageos-node-5qnl7                     3/3     Running   0          56s
storageos-node-7xc4s                     3/3     Running   0          52s
storageos-node-bkzkx                     3/3     Running   0          58s
storageos-node-gwp52                     3/3     Running   0          62s
storageos-node-zqkk7                     3/3     Running   0          62s
storageos-operator-8f7c946f8-npj7l       2/2     Running   0          64s
storageos-scheduler-86b979c6df-wndj4     1/1     Running   0          64s
```

> Wait until all the pods are ready. It usually takes ~60 seconds to complete

### License cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our
> personal license is free, and supports up to 1TiB of provisioned storage.

To obtain a license, follow the instructions on our [licensing operations](/docs//operations/licensing) page.

## Install Ondat on Kubernetes 1.19

### Install the storageos kubectl plugin

```
curl -sSLo kubectl-storageos.tar.gz \
    https://github.com/storageos/kubectl-storageos/releases/download/v1.0.0/kubectl-storageos_1.0.0_linux_amd64.tar.gz \
    && tar -xf kubectl-storageos.tar.gz \
    && chmod +x kubectl-storageos \
    && sudo mv kubectl-storageos /usr/local/bin/ \
    && rm kubectl-storageos.tar.gz
```

> 💡 You can find binaries for different architectures and systems in [kubectl
> plugin](https://github.com/storageos/kubectl-storageos/releases).

### Install Ondat

```bash
kubectl storageos install \
    --etcd-endpoints 'storageos-etcd-client.storageos-etcd:2379' \
    --admin-username "myuser" \
    --admin-password "my-password"
```

> 💡 Define the etcd endpoints as a comma delimited list, e.g. 10.42.3.10:2379,10.42.1.8:2379,10.42.2.8:2379

> 💡 If the etcd endpoints are not defined, the plugin will prompt you and
> request the endpoints.

### Verify Ondat installation

Ondat installs all its components in the `storageos` namespace.

```bash
$ kubectl -n storageos get pod -w
NAME                                     READY   STATUS    RESTARTS   AGE
storageos-api-manager-65f5c9dbdf-59p2j   1/1     Running   0          36s
storageos-api-manager-65f5c9dbdf-nhxg2   1/1     Running   0          36s
storageos-csi-helper-65dc8ff9d8-ddsh9    3/3     Running   0          36s
storageos-node-4njd4                     3/3     Running   0          55s
storageos-node-5qnl7                     3/3     Running   0          56s
storageos-node-7xc4s                     3/3     Running   0          52s
storageos-node-bkzkx                     3/3     Running   0          58s
storageos-node-gwp52                     3/3     Running   0          62s
storageos-node-zqkk7                     3/3     Running   0          62s
storageos-operator-8f7c946f8-npj7l       2/2     Running   0          64s
storageos-scheduler-86b979c6df-wndj4     1/1     Running   0          64s
```

> Wait until all the pods are ready. It usually takes ~60 seconds to complete

### License cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our
> personal license is free, and supports up to 1TiB of provisioned storage.

To obtain a license, follow the instructions on our [licensing operations](/docs/operations/licensing) page.


## Install Ondat on Kubernetes 1.18

### Install the storageos kubectl plugin

```
curl -sSLo kubectl-storageos.tar.gz \
    https://github.com/storageos/kubectl-storageos/releases/download/v1.0.0/kubectl-storageos_1.0.0_linux_amd64.tar.gz \
    && tar -xf kubectl-storageos.tar.gz \
    && chmod +x kubectl-storageos \
    && sudo mv kubectl-storageos /usr/local/bin/ \
    && rm kubectl-storageos.tar.gz
```

> 💡 You can find binaries for different architectures and systems in [kubectl
> plugin](https://github.com/storageos/kubectl-storageos/releases).

### Install Ondat

```bash
kubectl storageos install \
    --etcd-endpoints 'storageos-etcd-client.storageos-etcd:2379' \
    --admin-username "myuser" \
    --admin-password "my-password"
```

> 💡 Define the etcd endpoints as a comma delimited list, e.g. 10.42.3.10:2379,10.42.1.8:2379,10.42.2.8:2379

> 💡 If the etcd endpoints are not defined, the plugin will prompt you and
> request the endpoints.

### Verify Ondat installation

Ondat installs all its components in the `storageos` namespace.

```bash
$ kubectl -n storageos get pod -w
NAME                                     READY   STATUS    RESTARTS   AGE
storageos-api-manager-65f5c9dbdf-59p2j   1/1     Running   0          36s
storageos-api-manager-65f5c9dbdf-nhxg2   1/1     Running   0          36s
storageos-csi-helper-65dc8ff9d8-ddsh9    3/3     Running   0          36s
storageos-node-4njd4                     3/3     Running   0          55s
storageos-node-5qnl7                     3/3     Running   0          56s
storageos-node-7xc4s                     3/3     Running   0          52s
storageos-node-bkzkx                     3/3     Running   0          58s
storageos-node-gwp52                     3/3     Running   0          62s
storageos-node-zqkk7                     3/3     Running   0          62s
storageos-operator-8f7c946f8-npj7l       2/2     Running   0          64s
storageos-scheduler-86b979c6df-wndj4     1/1     Running   0          64s
```

> Wait until all the pods are ready. It usually takes ~60 seconds to complete

### License cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our
> personal license is free, and supports up to 1TiB of provisioned storage.

To obtain a license, follow the instructions on our [licensing operations](/docs/operations/licensing) page.


## Airgapped clusters

Airgapped clusters can install Ondat by defining the container images uploaded
on private registries using the Custom Resource definition of the
StorageOSCluster. Check the kubectl plugin reference for the 
[declarative installation](/docs/reference/kubectl-plugin#declarative-installation).

## First Ondat volume

If this is your first installation you may wish to follow the [Ondat Volume guide](/docs/operations/firstpvc) for an example of how
to mount an Ondat volume in a Pod.
