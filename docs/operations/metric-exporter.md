---
title: "Metric Exporter"
linkTitle: Metric Exporter
---

## Enable the metrics

To enable the Ondat Volume metrics, add the following field to your StorageOSCluster resource.

```yaml
spec:
  metrics:
    enabled: true
```

> ⚠️ On OCP you may need to follow their instructions for enabling monitoring of user-defined projects, [here](https://docs.openshift.com/container-platform/4.8/monitoring/enabling-monitoring-for-user-defined-projects.html)

## Example setup

Here’s an example [ServiceMonitor](https://prometheus-operator.dev/docs/operator/design/#servicemonitor) resource that scrapes our metrics endpoints:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: storageos
    release: prometheus
  name: storageos-metrics-service-monitor
  namespace: storageos
spec:
  endpoints:
  - interval: 15s
    path: /metrics
    port: metrics
  namespaceSelector:
    matchNames:
    - storageos
  selector:
    matchLabels:
      service-discovery: storageos-metrics-exporter
      app: storageos
```

⚠️ The label selector fields must match those of our service.

After the manifest is applied, Ondat metrics will be scraped by your Prometheus server.
