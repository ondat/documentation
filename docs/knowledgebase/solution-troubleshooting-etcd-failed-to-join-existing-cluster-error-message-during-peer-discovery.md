---
title: "Solution - Troubleshooting etcd 'failed to join existing cluster' Error Message During Peer Discovery"
linkTitle: "Solution - Troubleshooting etcd 'failed to join existing cluster' Error Message During Peer Discovery"
---

## Issue

You are experiencing an issue where nodes cannot successfully join the cluster. Upon investigation, you also notice the following error messages in the logs:

```bash
# Truncated output...
time="2018-09-24T13:40:20Z" level=info msg="not first cluster node, joining first node" action=create address=172.28.128.5 category=etcd host=node3 module=cp target=172.28.128.6
time="2018-09-24T13:40:20Z" level=error msg="could not retrieve cluster config from api" status_code=503
time="2018-09-24T13:40:20Z" level=error msg="failed to join existing cluster" action=create category=etcd endpoint="172.28.128.3,172.28.128.4,172.28.128.5,172.28.128.6" error="503 Service Unavailable" module=cp
time="2018-09-24T13:40:20Z" level=info msg="retrying cluster join in 5 seconds..." action=create category=etcd module=cp
# Truncated output...
```

## Root Cause

Ondat uses a  [gossip protocol](https://en.wikipedia.org/wiki/Gossip_protocol)  to discover nodes in the cluster. When Ondat starts, one or more nodes can be referenced so new nodes can query existing nodes for the list of members.
- The error demonstrated in the code snippet above indicates that the node can’t connect to any of the nodes in the known list. The known list is defined in the `JOIN` variable.
- If there are no active nodes, the bootstrap process will elect the first node in the `JOIN` variable as master, and the rest will try to discover from it. In case of that node not starting, the whole cluster will remain unable to bootstrap.
- Deployments of Ondat use a [Kubernetes DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/), and by default do not schedule Ondat pods to master nodes, due to the presence of the >> `node-role.kubernetes.io/master:NoSchedule` taint that is typically present. In such cases the `JOIN` variable must not contain master nodes or the Ondat cluster will not start.

## Resolution

- Check and ensure that the first node of the  `JOIN`  variable started properly.

	```bash
	# Describe the daemonset and grep for "JOIN".
	kubectl --namespace storageos describe daemonset.apps/storageos-node | grep "JOIN"

	    JOIN:          172.28.128.3,172.28.128.4,172.28.128.5

	# Check for the pod with the "172.28.128.3" IP address.
	kubectl --namespace storageos get pods --output wide | grep 172.28.128.3

	storageos-node-8zqxl   1/1       Running   0          2m        172.28.128.3   node1
	```

- Make sure that the `JOIN` variable doesn’t specify the master nodes. In case you are using the discovery service, it is necessary to ensure that the Ondat daemonset won’t allocate pods on the master nodes. This can be achieved with [taints](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/), node selectors or labels.
- For deployments with the Ondat operator you can specify which nodes to deploy Ondat on using [nodeSelectors](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/). 
	- For more information on how to configure the Ondat Custom Resource, review the [Ondat Operator Examples](/docs/reference/operator/examples/) page.
- For more advanced deployments that are using `compute-only` and storage nodes, check the >> `storageos.com/computeonly=true` label that can be added to the nodes through Kubernetes node labels has been configured correctly.
	- For more information on how to use the `storageos.com/computeonly=true` review the [How To Setup A Centralised Cluster Topology](https://docs.ondat.io/docs/operations/compute-only/) operations page.

## References

- [Gossip Protocol - Wikipedia](https://en.wikipedia.org/wiki/Gossip_protocol).
- [Taints and Tolerations - Kubernetes Documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/).
- [Assign Pods to Nodes - Kubernetes Documentation](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/).
- [Kubernetes DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/).
