---
title: "Metric Exporter"
linkTitle: Metric Exporter
---
## Overview
Following the [exporter pattern](https://prometheus.io/docs/instrumenting/exporters/), we maintain and distribute our own [Prometheus](https://prometheus.io/) exporter for monitoring & alerting of Ondat volumes. The metrics our exporter publishes include data on volume health, capacity & traffic.

Our exporter’s source code can be found [here](https://github.com/ondat/metrics-exporter).

Please see our [operations page](/docs/operations/metric-exporter/) to get started.

Additionally, we distribute Grafana dashboards to visualize the data. They can be found [here](https://github.com/ondat/metrics-exporter/tree/main/grafana).

Likewise, we distribute example alerting rules for our metrics using [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/), they can be found [here](https://github.com/ondat/metrics-exporter/tree/main/alertmanager)

Contributions to both are welcome!

> ⚠️ When installing be sure to create the rules in the same namespace as your Prometheus resource and match its ruleSelector field.

If you have suggestions for metrics you would like us to gather or improvements to our Grafana or Alertmanager integration, please let us know on our [public slack](https://slack.storageos.com/).
