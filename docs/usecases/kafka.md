---
title: "Kafka"
linkTitle: Kafka
---

![kafkalogo](/images/docs/explore/kafka.png)

Kafka is a popular stream processing platform combining features from pub/sub
and traditional queues.

Using Ondat persistent volumes with Apache Kafka means that if a pod
fails, the cluster is only in a degraded state for as long as it takes
Kubernetes to restart the pod. When the pod comes back up, the pod data is
immediately available. Should Kubernetes schedule the kafka pod on a
new node, Ondat allows for the data to be available to the pod,
irrespective of whether or not the original Ondat master volume
is located on the same node.

Kafka has features to allow it to handle replication, and as such careful
consideration of whether to allow Ondat or Kafka to handle replication
is required.

Before you start, ensure you have Ondat installed and ready on a Kubernetes
cluster. [See our guide on how to install Ondat on Kubernetes for more
information](/docs/install/kubernetes).

## Prerequisites

- Apache Zookeeper is required by Kafka to function; we assume it to already
exist and be accessible within the Kubernetes cluster as `zookeeper`, see how
to run Zookeeper with Ondat
[here](/docs/usecases/zookeeper)
- Ondat is assumed to have been installed; check for the latest
available version [here](/docs/reference/release_notes)
- Kafka pods require 1536 MB of memory for successful scheduling

### Helm

To simplify the deployment of kafka, we've used this
[Kafka helm chart (incubator)](https://github.com/helm/charts/tree/master/incubator/kafka)
(version `0.13.8`, app version `5.0.1`) and rendered it into the
example deployment files you can find in our GitHub
[repository](https://github.com/storageos/use-cases/tree/master/kafka).

#### Clone the use cases repository

You can find the latest files in the Ondat use cases repository
in `/kafka/`

  ```bash
git clone https://github.com/storageos/use-cases.git storageos-usecases
cd storageos-usecases
```

StatefulSet definition

  ```yaml
---
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: kafka
  labels:
    app: kafka
...
spec:
  serviceName: kafka-headless
  podManagementPolicy: OrderedReady
  updateStrategy:
    type: OnDelete
  replicas: 3                            # <--- number of kafa pods to run
  template:
...
    spec:
      serviceAccountName: kafka
      containers:
...
        - name: kafka-broker
          image: "confluentinc/cp-kafka:5.0.1"
          imagePullPolicy: "IfNotPresent"
...
          volumeMounts:
            - name: datadir
              mountPath: "/var/data"
      volumes:
        - name: jmx-config
          configMap:
            name: kafka-metrics
      terminationGracePeriodSeconds: 60
  volumeClaimTemplates:
    - metadata:
        name: datadir
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi               # <--- storage requested for each pod
        storageClassName: "storageos"   # <--- the StorageClass to use
```

  This excerpt is from the StatefulSet definition (`10-statefulset.yaml`). The
  file contains the PersistentVolumeClaim template that will dynamically
  provision the necessary storage, using the Ondat storage class.

  Dynamic provisioning occurs as a volumeMount has been declared with the same
  name as a VolumeClaimTemplate.

1. Create the kubernetes objects

   ```bash
   kubectl apply -f ./kafka/
    ```

1. Confirm kafka is up and running

   ```bash
   $ kubectl get pods -l app=kafka
   NAME      READY   STATUS    RESTARTS   AGE
   kafka-0   2/2     Running   0          10m
   kafka-1   2/2     Running   0          9m26s
   kafka-2   2/2     Running   0          7m59s
   ```

1. Connect to kafka

   Connect to the kafka test client pod and send some test data to kafka through
   its service endpoint

1. Connect to the pod

   ```bash
   kubectl exec -it kafka-test-client /bin/bash
   ```

1. Create a topic

   ```bash
   /usr/bin/kafka-topics --zookeeper zookeeper:2181 --create --topic test-rep-one --partitions 6 --replication-factor 1
   ```

1. Send some test data

   ```bash
   /usr/bin/kafka-run-class org.apache.kafka.tools.ProducerPerformance --topic test-rep-one --num-records 5000 --record-size 100 --throughput -1 --print-metrics --producer-props acks=1 bootstrap.servers=kafka:9092 buffer.memory=67108864 batch.size=8196
   ```
