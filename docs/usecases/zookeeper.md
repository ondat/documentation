---
title: "Zookeeper"
linkTitle: Zookeeper
---

![zookeeperlog](/images/docs/explore/zookeeper.png)

ZooKeeper is a centralized service for maintaining configuration information,
naming, providing distributed synchronization, and providing group services.

Using Ondat persistent volumes with Apache Zookeeper means that if a pod
fails, the cluster is only in a degraded state for as long as it takes
Kubernetes to restart the pod. When the pod comes back up, the pod data is
immediately available. Should Kubernetes schedule the Zookeeper pod on a
new node, Ondat allows for the data to be available to the pod,
irrespective of whether or not the original Ondat master volume
is located on the same node.

As Zookeeper has features to allow it to handle replication, and as such
careful consideration of whether to allow Ondat or Zookeeper to handle replication is required.

Before you start, ensure you have Ondat installed and ready on a Kubernetes
cluster. [See our guide on how to install Ondat on Kubernetes for more
information](/docs/install/kubernetes).

## Deploying Zookeeper on Kubernetes

### Pre-requisites

- Ondat is assumed to have been installed; please check for the latest
available version [here](/docs/reference/release_notes).

### Helm

To simplify the deployment of Zookeeper, we've used this [Zookeeper helm chart
(incubator)](https://github.com/helm/charts/tree/master/incubator/zookeeper)
(version `1.2.2`, app version `3.4.10`) and rendered it into the example
deployment files you can find in our GitHub
[repo](https://github.com/storageos/use-cases/tree/master/zookeeper).

### Deployment

#### Clone the use cases repo

You can find the latest files in the Ondat use cases repository in
`/zookeeper/`

  ```bash
git clone https://github.com/storageos/use-cases.git storageos-usecases
```

#### StatefulSet defintion

  ```yaml
---
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: zookeeper
...
spec:
  replicas: 3                             # <--- number of zookeeper pods
...
      containers:
        - name: zookeeper
          image: "gcr.io/google_samples/k8szk:v3"
          imagePullPolicy: IfNotPresent
...
          volumeMounts:
            - name: data
              mountPath: /var/lib/zookeeper
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes:
          - "ReadWriteOnce"
        storageClassName: "storageos"     # <--- the StorageClass to use
        resources:
          requests:
            storage: "5Gi"                # <--- storage requested per pod
  ```

  This excerpt is from the StatefulSet definition (`10-statefulset.yaml`).
  The file contains the PersistentVolumeClaim template that will dynamically
  provision the necessary storage, using the Ondat storage class. Dynamic
  provisioning occurs as a volumeMount has been declared with the same name
  as a VolumeClaimTemplate.

#### Create the kubernetes objects

  ```bash
cd storageos-usecases
kubectl apply -f ./zookeeper/
```

#### Confirm Zookeeper is up and running

  ```bash
$ kubectl get pods

NAME                    READY   STATUS    RESTARTS   AGE
zookeeper-0             1/1     Running   0          2m30s
zookeeper-1             1/1     Running   0          112s
zookeeper-2             1/1     Running   0          56s
zookeeper-test-client   1/1     Running   0          2m30s
```

#### Connect to Zookeeper

Connect to the zookeeper client pod and list existing topics using the
service endpoint

  ```bash
kubectl exec -it zookeeper-test-client /bin/bash
```

and issue a command to the zookeeper service

  ```bash
zkCli.sh -server zookeeper ls /zookeeper
```
