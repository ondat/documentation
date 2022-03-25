---
linkTitle: "Rolling Upgrades to Orchestrator"
---

# Overview

You can use the rolling upgrade feature to upgrade an orchestrator of your choice without causing service downtime/cluster failure. This feature enables you to avoid significant service downtime during a rolling upgrade of the Orchestrator that Ondat is running on.

If the volume replicas containing data for your stateful workloads do not wait on successfully synchronizing in-between the node upgrades, this can potentially cause data inconsistency and loss.

Ondat has developed a new solution to solve this problem for you. For example, Ondat would now be able to support the OpenShift one-click upgrade without any downtime on your side.

To use the rolling upgrade feature, follow these steps [here](docs/operations/using-rolling-upgrades).
