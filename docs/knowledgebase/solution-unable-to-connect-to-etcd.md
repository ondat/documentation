---
title: "Solution - Troubleshooting 'unable to connect to etcd' Error Message"
linkTitle: "Solution - Troubleshooting 'unable to connect to etcd' Error Message"
---

## Issue

- When reviewing the status of the Ondat daemonset pods named `storageos-node-xxxx`, the pods are fail to startup and are stuck in a `CrashLoopBackOff` state loop.

```bash
# Get the pods in the "storageos" namespace
kubectl get pods --namespace storageos

storageos             storageos-node-6v9x2                               3/3     Running            2 (16s ago)   55s
storageos             storageos-node-g7vhn                               2/3     CrashLoopBackOff   1 (14s ago)   55s
storageos             storageos-node-ph567                               3/3     Running            2 (17s ago)   55s
storageos             storageos-node-tw8fk                               2/3     CrashLoopBackOff   1 (12s ago)   55s
storageos             storageos-node-xtvgd                               3/3     Running            2 (12s ago)   55s
```

- Upon reviewing the logs for one of the failing daemonset pods, there is an `"unable to connect to etcd"` error message and `"failed to initialise store client"` error message that shows up before the pod shutsdown and restarts.

```bash
# Check the logs of a Ondat daemonset that is in a "CrashLoopBackOff" loop.
kubectl logs storageos-node-tw8fk --namespace storageos

{"endpoints":["http://10.73.16.8:2379"],"error":"context deadline exceeded","level":"error","msg":"unable to connect to etcd","store":"etcd","time":"2022-02-13T19:17:35.556128015Z"}
{"error":"failed to instantiate ETCD: context deadline exceeded","level":"error","msg":"failed to initialise store client","time":"2022-02-13T19:17:35.55625352Z"}
{"level":"info","msg":"shutting down","time":"2022-02-13T19:17:35.556274893Z"}
```

## Root Cause

- This issue is cause by the Ondat daemonset pods not being able to connect to the `etcd` cluster. This is generally caused by `etcd`  being unreachable due to [network partitioning](https://en.wikipedia.org/wiki/Network_partition) or misconfiguration.

## Resolution

- Ensure that your `etcd` cluster is healthy.
- Ensure that etcd is running.
- Ensure that the `etcd` URL that is set in the `StorageOSCluster` custom resource is correct and it includes the port number.
- Ensure that the `etcd` peers are routable from the `etcd` advertise addresses of each peer, and not only from a load balancer.
- Ensure that `etcd`  is routable from the network where the worker nodes reside.
