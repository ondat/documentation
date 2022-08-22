---
title: "Solution - Cannot Perform Ondat Operations To Volumes Or Nodes"
linkTitle: "Solution - Cannot Perform Ondat Operations To Volumes Or Nodes"
---

## Issue

You are experiencing issues with performing operations to volumes and nodes in an Ondat cluster. Below are some of the operations that you are unable to execute;
- A specific `PersistentVolumeClaim` (PVC) can’t be created or deleted successfully.

```bash
# Describe the PVC named "my-pvc".
kubectl describe pvc my-pvc

# truncated output...
Events:
  Type     Reason                Age                 From                                                                                         Message
  ----     ------                ----                ----                                                                                         -------
  Warning  ProvisioningFailed    27s (x9 over 10m)   csi.storageos.com_storageos-csi-helper-f7569f986-6prpq_debad2f4-27a8-4033-81af-7fb2e338afd4  failed to provision volume with StorageClass "storageos": rpc error: code = DeadlineExceeded desc = context deadline exceeded
```

- Volumes cannot be used (ie, failing to attach and mount) and are reporting a `FailedScheduling` event.

```bash
# Describe the pod "d2".
kubectl describe pod d2

# truncated output...
Events:
  Type     Reason            Age   From                 Message
  ----     ------            ----  ----                 -------
  Warning  FailedScheduling  4s    storageos-scheduler  Post "http://storageos:5705/v2/k8s/scheduler/filter": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
```

- Volumes are not successfully failing over.
- Nodes cannot be added or deleted.

In addition, when reviewing the logs for the Ondat daemonset, you may see the following `error` and `warning` messages;

```bash
# Get the logs for the Ondat daemonset/
kubectl logs daemonsets.apps/storageos-node  --namespace=storageos

# truncated output...
{"auth_req_username":"storageos","error":"context deadline exceeded","level":"error","msg":"error while performing login","req_id":"4ba51f16-0f69-4b4f-bb83-0d7f9b58ff0c","req_ip":"10.73.0.217:49118","req_xff":"","time":"2022-02-13T18:48:54.796090712Z"}
{"error":"context deadline exceeded","level":"error","msg":"storing remote capacity failed","node_id":"d8d3d8dc-c3cd-4f97-86fb-4706d01dff33","time":"2022-02-13T18:49:03.674273759Z"}
{"error":"context deadline exceeded","level":"warning","msg":"failed to update node size value in remote store","node_id":"d8d3d8dc-c3cd-4f97-86fb-4706d01dff33","time":"2022-02-13T18:49:03.674370036Z"}
{"error":"context deadline exceeded","level":"error","msg":"failed to fetch latest available licence information","time":"2022-02-13T18:49:03.675980929Z"}
{"error":"context deadline exceeded","level":"warning","msg":"lock operation failure - is etcd healthy?","node_id":"d8d3d8dc-c3cd-4f97-86fb-4706d01dff33","store_lock_key":"storageos/default/v1/locks/node/d8d3d8dc-c3cd-4f97-86fb-4706d01dff33","time":"2022-02-13T18:49:11.026773582Z"}
{"error":"context deadline exceeded","level":"error","msg":"abandoning expired lock","node_id":"d8d3d8dc-c3cd-4f97-86fb-4706d01dff33","store_lock_key":"storageos/default/v1/locks/node/d8d3d8dc-c3cd-4f97-86fb-4706d01dff33","time":"2022-02-13T18:49:11.026865788Z"}

# Use jq for clearer formatting and only show the error messages in the daemonset pods.
kubectl logs daemonsets.apps/storageos-node  --namespace=storageos | jq '{msg: .msg, error: .error}'

{
"msg": "storing remote capacity failed",
"error": "context deadline exceeded"
}
{
"msg": "failed to update node size value in remote store",
"error": "context deadline exceeded"
}
{
"msg": "failed to fetch latest available licence information",
"error": "context deadline exceeded"
}
{
"msg": "lock operation failure - is etcd healthy?",
"error": "context deadline exceeded"
}
{
"msg": "abandoning expired lock",
"error": "context deadline exceeded"
}
{
"msg": "error during authentication",
"error": "context deadline exceeded"
}
```

## Resolution

- To resolve the operations issues, this will require assessing and repairing the  `etcd`  cluster and ensuring that the cluster is healthy again - whether the issue is `etcd`, your network configuration, or because the nodes where Ondat is deployed are overutilised to the point where they cannot fulfil requests to and from `etcd` successfully.

1. Ensure that your `etcd` cluster is running and is healthy.
    1. `etcdctl member list -wtable`
    1. `etcdctl endpoint status -wtable`
    1. `etcdctl endpoint health -wtable`
2. Check to see if your `etcd` cluster has lost [quorum](https://en.wikipedia.org/wiki/Quorum) by reviewing the `etcd` logs.
3. Check to see if your `etcd` cluster is routable.
4. Check to see if your `etcd` cluster is in a Read Only (RO) state that has been caused by an `etcd` alarm.
    1. `etcdctl alarm list`
5. Check to see if your `etcd` cluster is struggling to write to disk fast enough (`etcd` is sensitive to latency on disk).
    1. Review the logs and prometheus monitoring metrics for `disk_wal_fsync` and `db_fsync` and check to see if there is any performance degradation. (ie, orders of seconds rather than milliseconds or nanoseconds).
6. If your `etcd` cluster is healthy and routable, check to see if the nodes running the Ondat daemonset pods `daemonsets.apps/storageos-node` are healthy.
    1. Are the pods under unusual load?
    1. Are there any errors being reported in one daemonset pod or more?

## Root Cause

- The `error` messages that are returned from the Ondat daemonset `daemonsets.apps/storageos-node` indicates that the daemonset pods cannot successfully communicate with the `etcd` cluster.
