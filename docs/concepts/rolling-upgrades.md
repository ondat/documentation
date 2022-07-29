---
title: "Ondat Rolling Upgrades Protection For Orchestrators"
linkTitle: "Ondat Rolling Upgrades Protection For Orchestrators"
weight: 1
---

## Overview

> 💡 This feature is currently available as a Technical Preview from release `2.7.0` or greater.

### Rolling Upgrades Protection

You can use our rolling upgrade protection feature to upgrade your cluster's orchestrator without causing downtime or failure of Ondat.

- If the volumes containing the data for your stateful workloads do not wait to successfully synchronize in-between nodes upgrading, this can potentially cause data inconsistency and downtime. As such it is necessary to perform these upgrades intelligently.
- We are developing a solution to this problem for you. It is currently a Technical Preview but now, for example, Ondat can support a [Google Anthos](/docs/install/anthos/) one-click upgrade without any downtime.

To get started with Ondat's Rolling Upgrades Protection for your cluster, review the [Platform Upgrade](/docs/operations/using-rolling-upgrades) page for more information.
