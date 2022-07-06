---
title: "Metric Exporter"
linkTitle: "Metric Exporter"
weight: 1
---
## Overview

Following the [exporter pattern](https://prometheus.io/docs/instrumenting/exporters/), we maintain and distribute our own [Prometheus](https://prometheus.io/) exporter for monitoring & alerting of Ondat volumes. The metrics our exporter publishes include data on volume health, capacity & traffic.

Our exporter’s source code can be found [here](https://github.com/ondat/metrics-exporter).

Please see our [operations page](/docs/operations/metric-exporter/) to get started.

Additionally, we distribute Grafana dashboards to visualize the data. They can be found [here](https://github.com/ondat/metrics-exporter/tree/main/grafana).

Likewise, we distribute example alerting rules for our metrics using [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/), they can be found [here](https://github.com/ondat/metrics-exporter/tree/main/alertmanager)

Contributions to both are welcome!

> ⚠️ When setting up a [ServiceMonitor](https://github.com/prometheus-operator/prometheus-operator/blob/1e4acb010642067bb918eebb75410191640a95c6/Documentation/user-guides/getting-started.md) be sure to create the rules in the same namespace as your Prometheus resource and have its `selector` field match the labels of ours services exposing metrics (see example manifest [here](/docs/operations/metric-exporter/)).

If you have suggestions for metrics you would like us to gather or improvements to our Grafana or Alertmanager integration, please let us know on our [public slack](https://slack.storageos.com/).
