---
title: "How To Enable Fencing"
linkTitle: How To Enable Fencing
---

## Overview

> 💡 For more information on the Ondat fencing feature, review the [Fencing](/docs/concepts/fencing) feature page.

### How To Label a Pod for Fencing?

When Ondat detects that a node has gone offline or become partitioned, it marks the node offline and performs volume failover operations.

- The [Ondat Fencing Controller](https://github.com/storageos/api-manager/tree/master/controllers/fencer) watches for node failures and determines if there are any pods targeted for fencing.

In order for a pod to be fenced, the following criteria listed below is required:

1. The pod must have the label `storageos.com/fenced=true`.
1. The pod to be fenced must claim an Ondat volume.
1. The Ondat volume claimed by the pod needs to be `online`.

If the node becomes offline and these criteria are met, the pod is deleted and rescheduled on another node.

> 💡 No changes are made to pods that have Ondat volumes that are unhealthy. This is typically the case when a volume was configured to not have any replicas, and the node with the single copy of the data is offline. In this case it is better to wait for the node to recover.

### Example - Enable Fencing for a StatefulSet Workload

Below is an example that shows how a [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) can leverage fencing for its associated pods.

> 💡 Note that the `storageos.com/fenced: "true"` label is applied only in the `.spec.template.metadata.label` section, as the label must only be present on the pod, but not on the PVC. Otherwise, the Ondat volumes will fail to provision as only special accepted labels can be passed to volumes.

```yaml
# Create a "my-statefulset" resource with a fencing enabled. 
cat <<EOF | kubectl create --filename -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: my-statefulset
spec:
  selector:
    matchLabels:                       # Notice that the "matchLabels" does NOT have the fencing label.
      app: prod
  serviceName: "default"
  replicas: 1
  template:
    metadata:
      labels:                          # Notice that the fencing label IS PRESENT here.
        app: prod
        storageos.com/fenced: "true"   # Enable Ondat fencing.
    spec:
      containers:
      - name: debian
        image: debian:10-slim
        command: ["/bin/sleep"]
        args: [ "3600" ]
        volumeMounts:
        - name: storageos-volume
          mountPath: /mnt
  volumeClaimTemplates:
  - metadata:
      name: storageos-volume
      labels:
        env: prod
        storageos.com/replicas: "1"
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "storageos"
      resources:
        requests:
          storage: 10Gi
EOF
```

Once the resource has been successfully created and is running, review and confirm that the `storageos.com/fenced: "true"` label has been applied to the StatefulSet.

```bash
 # Get the labels applied to the "my-statefulset-0" pod.
kubectl get pod my-statefulset-0 --namespace=default --show-labels --output=wide

NAME               READY   STATUS    RESTARTS   AGE     IP           NODE                              NOMINATED NODE   READINESS GATES   LABELS
my-statefulset-0   1/1     Running   0          2m34s   10.244.4.6   aks-storage-41375452-vmss000001   <none>           <none>            app=prod,controller-revision-hash=my-statefulset-d7dc867bf,statefulset.kubernetes.io/pod-name=my-statefulset-0,storageos.com/fenced=true
```

## Understanding Ondat's Fencing Trigger

The Ondat Fencing Controller checks the Ondat node health **every `5` seconds**. This is how quickly the fencing controller can react to node failures.

- Pods assigned to unhealthy nodes will be evaluated immediately on state change, and then re-evaluated every hour, though this is configurable.
- This retry allows pods that had unhealthy volumes which have now recovered to eventually failover, or pods that were rescheduled on an unhealthy node to be re-evaluated for fencing.

### Fencing Trigger Demonstration

The following example below shows how the Ondat API manager fences a pod.

1. Ensure the `storageos.com/fenced=true` label is present:

    ```bash
    # Get the labels applied to the "mysql" pod.
    kubectl --namespace=mysql get pod --show-labels --output=wide
    
    NAME      READY   STATUS    RESTARTS   AGE     IP          NODE             NOMINATED NODE   READINESS GATES   LABELS
    mysql-0   1/1     Running   0          6m33s   10.42.3.7   worker1   <none>           <none>            app=mysql,controller-revision-hash=mysql-799fd74b87,env=prod,statefulset.kubernetes.io/pod-name=mysql-0,storageos.com/fenced=true

    # Get the labels applied to the "mysql" PVC.
    kubectl --namespace=mysql get pvc --show-labels --output=wide
    
    NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE   LABELS
    data-mysql-0   Bound    pvc-5d7b23a6-e754-4998-98fd-318b3f9382bb   5Gi        RWO            storageos      19m   Filesystem   app=mysql,env=prod,storageos.com/replicas=1
    ```

    > 💡 Notice that the `mysql-0` pod above has the `storageos.com/fenced=true` label and is on `worker1` node.

1. Purposefully stop the node that is hosting the `mysql-0` pod:

    ```bash
    # SSH to "worker1" node.
    ssh worker1
    # Shut down "worker1" node.
    shutdown -h now
    ```

1. Check the logs from the Ondat API Manager:

    ```bash
    # Get the logs from the Ondat API Manager.
    kubectl --namespace=storageos logs storageos-api-manager-68759bbc78-7l5fw
    
    # truncated...
    {"level":"info","timestamp":"2021-04-28T13:06:49.413811357Z","msg":"skipping pod without storageos.com/fenced=true label set","name":"nginx-ingress-controller-xbqjf","namespace":"ingress-nginx"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.417605039Z","msg":"skipping pod without storageos.com/fenced=true label set","name":"storageos-api-manager-68759bbc78-7l5fw","namespace":"storageos"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.417748651Z","msg":"skipping pod without storageos.com/fenced=true label set","name":"coredns-7c5566588d-8g5xq","namespace":"storageos"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.417792281Z","msg":"skipping pod without storageos.com/fenced=true label set","name":"metrics-server-6b55c64f86-cnwtk","namespace":"storageos"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.417883383Z","msg":"skipping pod without storageos.com/fenced=true label set","name":"default-http-backend-67cf578fc4-w8sm4","namespace":"ingress-nginx"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.417975663Z","msg":"skipping pod without storageos.com/fenced=true label set","name":"coredns-autoscaler-65bfc8d47d-ph6pn","namespace":"storageos"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.418024204Z","msg":"skipping pod without storageos.com/fenced=true label set","name":"canal-stzdv","namespace":"storageos"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.418065315Z","msg":"skipping pod without storageos.com/fenced=true label set","name":"storageos-etcd-2hkff82fq2","namespace":"storageos-etcd"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.418092165Z","msg":"skipping pod without storageos.com/fenced=true label set","name":"storageos-daemonset-6zrkk","namespace":"storageos"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.418182036Z","msg":"skipping pod without storageos.com/fenced=true label set","name":"cattle-node-agent-sjspk","namespace":"cattle-system"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.439513312Z","msg":"pod has fenced label set and volume(s) still healthy after node failure, proceeding with fencing","pod":"mysql-0","namespace":"mysql"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.495807296Z","msg":"pod deleted","pod":"mysql-0","namespace":"mysql"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.505411162Z","msg":"volume attachment deleted","pod":"mysql-0","namespace":"mysql","pvc":"data-mysql-0","va":"csi-c2b44cee5a647e20d77e0e217dfaec07afd592eae57bcccc09b3447de653ae8c","node":"worker1"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.505439792Z","msg":"fenced pod"}
    {"level":"info","timestamp":"2021-04-28T13:06:49.573478266Z","msg":"set scheduler","scheduler":"storageos-scheduler","pod":"mysql/mysql-0"}
    # truncated...
    ```

    > 💡 The Ondat API Manager detects all the pods that are on the failed node, and selects only the ones that meet the fencing criteria as described above. In this case only `mysql-0` is selected for fencing.

1. Check the pod's new node location:

    ```bash
    # Get the labels applied to the "mysql" pod.
    kubectl --namespace=mysql get pod --show-labels --output=wide
    
    NAME      READY   STATUS    RESTARTS   AGE     IP          NODE             NOMINATED NODE   READINESS GATES   LABELS
    mysql-0   1/1     Running   0          6m33s   10.42.3.7   worker2   <none>           <none>            app=mysql,controller-revision-hash=mysql-799fd74b87,env=prod,statefulset.kubernetes.io/pod-name=mysql-0,storageos.com/fenced=true
    ```

    > 💡 Notice that the pod `mysql-0` started on a different node successfully.
