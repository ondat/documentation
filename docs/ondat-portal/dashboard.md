---
title: " Dashboard Page Reference"
linkTitle: "Dashboard Page Reference"
---


The __Dashboard__ gives you an unified and summarised view of the application you have deployed. If there are any persistent volumes in error this will be indicated on the dashboard as a red side line next to the application name and will also give you the number of affected volumes.

Your deployed application can be one of the following types:
* __Replica__ - ensures that one or more pods are running at any given time, according to configuration. Usually, `ReplicaSets` are managed by Deployments.
* __StatefulSet__ - represents a stateful application that both manages one or more pods, ensures that they are running at any given time and provides certain guarantees about the order and uniqueness of the pods.
* __Deployment__ - provides a desired state for one or more sets of pods without guaranteeing order or uniqueness.
  
  To view more details about each application, go to the __Applications__ tab. 