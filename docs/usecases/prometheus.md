---
title: "Prometheus"
linkTitle: Prometheus
---

![prometheuslogo](/images/docs/explore/prom.png)

Prometheus is a popular application used for event monitoring and alerting in
Kubernetes.

Before you start, ensure you have Ondat installed and ready on a Kubernetes
cluster. [See our guide on how to install Ondat on Kubernetes for more
information](/docs/install/kubernetes).

## Deploying Prometheus on Kubernetes

This is the Prometheus use case for Ondat. Following are the steps for
creating a Prometheus StatefulSet and using Ondat to provide persistent
storage.

1. You can find the latest files in the Ondat use cases repository

   ```bash
   git clone https://github.com/storageos/use-cases.git storageos-usecases
   ```

   Prometheus Custom Resource definition

   ```yaml
    apiVersion: monitoring.coreos.com/v1
    kind: Prometheus
    metadata:
      name: prometheus-storageos
      labels:
        app: prometheus-operator
    spec:
      ...
      storage:
        volumeClaimTemplate:
          metadata:
            name: data
            labels:
              env: prod
        spec:
          accessModes: ["ReadWriteOnce"]
          storageClassName: ondat-replicated
          resources:
            requests:
              storage: 1Gi
    ```

   This excerpt is from the Prometheus Custom Resource definition. This file
   contains the VolumeClaimTemplate that will dynamically provision storage,
   using the Ondat storage class. Dynamic provisioning occurs due to the
   VolumeClaimTemplate in the Prometheus StatefulSet. The Prometheus
   StatefulSet is created by the Prometheus Operator, triggered by the creation
   of the Prometheus resource.

1. Move into the Prometheus examples folder and install the Prometheus Operator
   and create a Prometheus resource.

   ```bash
   cd storageos-usecases/prometheus
   ./install-prometheus.sh
   ```

1. Confirm Prometheus is up and running.

   ```bash
   $ kubectl get pods -w -l app=prometheus
   NAME                                READY   STATUS              RESTARTS   AGE
   prometheus-prometheus-storageos-0   3/3     READY               0          1m
   ```

1. You can see the created PVC using.

    ```bash
    $ kubectl get pvc
    NAME                                     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
    data-prometheus-prometheus-storageos-0   Bound    pvc-b6c17c0a-e76b-4a0b-8fc6-46c0e1629210   1Gi        RWO            ondat-replicated   65m
    ```

1. In the Prometheus deployment script, a service monitor is created. A Service
   Monitor is a special object that the Prometheus operator uses to create
   configuration for Endpoints for Prometheus to scrape. Although the name
   implies that a Service Monitor defines Kubernetes services that will be
   scraped, Prometheus actually targets the Endpoints that the services point
   to. The new Prometheus instance will use the storageos-etcd service monitor
   to start scraping metrics from the storageos-etcd pods. Assuming the
   storageos cluster was setup using ETCD as pods. For more information about
   service monitors, have a look at the upstream
   [documentation](https://prometheus-operator.dev/docs/user-guides/getting-started/).

    ```bash
    $ kubectl get servicemonitor                       
    NAME             AGE
    storageos-etcd   5d1h
    ```

1. The Prometheus web ui can be accessed by port-forwarding the Prometheus pods
   port to localhost.

   ```bash
   kubectl port-forward prometheus-prometheus-storageos-0 9090
   ```

   Then launch a web browser and go to `localhost:9090` to access the
   Prometheus web ui. You can confirm that the storageos-etcd target is
   configured there.

## Configuration

In the `storageos-usecases/prometheus/manifests/prometheus` directory there are
other example Service Monitors. For more information about Prometheus,
check out the [prometheus documentation](https://prometheus.io/docs/).
