---
linkTitle: Ondat Scheduler
---

# Ondat Scheduler

Ondat has the capacity to influence Kubernetes Pod placement decisions to
ensure that Pods are scheduled on the same nodes as their data. This
functionality is known as `Pod Locality`.

Ondat grants access to data by presenting, on local or remote nodes, the
devices used in a Pod's VolumeMounts. However, it is often the case that it is
required or preferred to place the Pod on the node where the Ondat Primary
Volume is located, because IO operations are fastest as a result of minimized
network traffic and associated latency. Read operations are served locally and
writes require fewer round trips to the replicas of the volume.

Ondat automatically enables the use of a custom scheduler for any Pod
using Ondat Volumes. Checkout the [Admission Controller reference](/docs/reference/scheduler/admission-controller) for more
information.


## Storageos Kubernetes Scheduler

Ondat achieves Pod locality by implementing a Kubernetes scheduler
extender. The Kubernetes standard scheduler interacts with the Ondat
scheduler when placement decisions need to be made.

The Kubernetes standard scheduler selects a set of nodes for a placement
decision based on nodeSelectors, affinity rules, etc. This list of nodes is
sent to the Ondat scheduler which sends back the target node where the Pod
shall be placed.

The Ondat scheduler logic is provided by a Pod in the Namespace where
Ondat Pods are running.

## Scheduling process

When a Pod needs to be scheduled, the scheduler collects information
about all available nodes and the requirements of the Pod. The collected
data is then passed through the Filter phase, during which the scheduler predicates
are applied to the node data to decide if the given nodes are compatible
with the Pod requirements. The result of the filter consists of a list of nodes
that are compatible for the given Pod and a list of nodes that aren't
compatible.

The list of compatible nodes is then passed to the Prioritize phase, in which
the nodes are scored based on attributes such as the state. The result of the
Prioritize phase is a list of nodes with their respective scores. The more
favorable nodes get higher scores than less favorable nodes. The list is then
used by the scheduler to decide the final node to schedule the Pod on.

Once a node has been selected, the third phase, Bind, handles the binding
of the Pod to the Kubernetes apiserver. Once bound, the kubelet on the node
provisions the Pod.

The Ondat scheduler implement Filter and Prioritization phases and leaves
binding to the default Kubernetes scheduler.

```bash
    Available         +------------------+                     +------------------+
  NodeList & Pod      |                  |  Filtered NodeList  |                  |    Scored
   Information        |                  |  & Pod Information  |                  |   NodeList
+-------------------->+      Filter      +-------------------->+    Prioritize    |--------------->
                      |   (Predicates)   |                     |   (Priorities)   |
                      |                  |                     |                  |
                      +------------------+                     +------------------+

```


## Scheduling Rules

The Ondat scheduler filters nodes ensuring that the remaining subset
fulfill the following prerequisites:

- The node is running Ondat
- The node is healthy

