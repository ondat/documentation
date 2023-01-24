---
title: "How to Set Ondat Container Resource Requests and Limits"
linkTitle: "How to Set Ondat Container Resource Requests and Limits"
---

## Overview

With Ondat, cluster administrators can configure each individual Ondat container with specific requests and limits for CPU and memory resources.

## Procedure

Edit the `containerResources` field in your `storageoscluster` spec to reflect your desired resources for the chosen containers. The below snippet is an example showing resource settings for the Ondat API-Manager and Ondat Scheduler.

```yaml
spec:
  containerResources:
    apiManagerContainer:
      limits:
        cpu: 110m
        memory: 200Mi
      requests:
        cpu: 20m
        memory: 600Mi
    kubeSchedulerContainer:
      limits:
        cpu: 110m
        memory: 200Mi
      requests:
        cpu: 20m
        memory: 600Mi
```

If the cluster administrator performs this update successfully on a running cluster, the operator will restart the specified container(s) with the desired resource configurations.

**Note**: If the updated requests/limiits force a change in pod [QoS](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/#create-a-pod-that-gets-assigned-a-qos-class-of-guaranteed) (eg best-effort to guaranteed), then the affected deployment/daemonset will need to be manually deleted **after** the update. Once deleted, the operator will recreate the object with the correct resources and subsequent QoS.
