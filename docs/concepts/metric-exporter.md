---
title: "Ondat Metric Exporter"
linkTitle: "Ondat Metric Exporter"
weight: 1
---

## Overview

> 💡 This feature is available in release `v2.8.0` or greater.

### Prometheus Metrics for Ondat Volumes

Following the [exporter pattern](https://prometheus.io/docs/instrumenting/exporters/), we maintain and distribute our own [Prometheus](https://prometheus.io/) exporter for monitoring and alerting of Ondat volumes. The metrics our exporter publishes include data on volume health, capacity and traffic.

- The Ondat metric exporter repository is open source and can be located on [GitHub](https://github.com/ondat/metrics-exporter).

To get started with installing and configuring the exporter in your Ondat cluster, review the [metric exporter's](/docs/operations/metric-exporter/) operations page for more information.

> ⚠️ When setting up a [ServiceMonitor](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/getting-started.md) resource, ensure that you create the rules in the same namespace as your Prometheus resource and have its `selector` field match the labels of the services exposing metrics - review the [example ServiceMonitor resource](/docs/operations/metric-exporter/) manifest in the operations page for more information.

### Alerting Rules for Ondat Volumes

Ondat also distributes example alert rules for Ondat metrics using [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/).

- The alert rules manifest can be located in the [`alertmanager` sub directory under the Ondat metric exporter](https://github.com/ondat/metrics-exporter/tree/main/alertmanager) repository.

### Grafana Dashboard for Ondat Volumes

In addition to the Ondat metric exporter project, we also distribute [Grafana dashboards](https://grafana.com/grafana/dashboards/) that allow end users to easily visualize and get insights into the status of Ondat volumes.

- The dashboards can be also located in the [`grafana` sub directory under the Ondat metric exporter](https://github.com/ondat/metrics-exporter/tree/main/grafana) repository.

## Contributing

If end users have suggestions/ideas for metrics that they would like Ondat to gather by default or improve the Grafana dashboards and Alertmanager integration, contributions are welcome.

You can reach out to us on the [Ondat community slack workspace](https://slack.storageos.com/) or review the [contributing guidelines](https://github.com/ondat/metrics-exporter/blob/main/CONTRIBUTING.md) in the Ondat metric exporter repository.
