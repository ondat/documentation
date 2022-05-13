---
link: Rolling Upgrades to Orchestrator
linkTitle: "Rolling Upgrades to Orchestrator"
---

# Overview

You can use our rolling upgrade protection feature to upgrade your cluster's orchestrator without causing downtime or failure of Ondat.

If the volumes containing the data for your stateful workloads do not wait to successfully synchronize in-between nodes upgrading, this can potentially cause data inconsistency and downtime. As such it is necessary to perform these upgrades intelligently.

We are developing a solution to this problem for you. It is currently a tech preview but now, for example, Ondat can support a Google Anthos one-click upgrade without any downtime.

To use the rolling upgrade feature, follow the steps [here](/docs/operations/using-rolling-upgrades).
