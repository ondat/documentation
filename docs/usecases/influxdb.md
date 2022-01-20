---
title: "InfluxDB"
linkTitle: InfluxDB
---

![influxdblogo](/images/docs/explore/influxdb.png)

InfluxDB is a popular open source time series database application optimised
for managing datasets consisting of many small measurements. Its advantages
include the ability to handle very high write and query loads. Its uses include monitoring, analytics and the recording and analysis of data from sensors.

Before you start, ensure you have Ondat installed and ready on a Kubernetes cluster. [See our guide on how to install Ondat on Kubernetes for more information](/docs/install/kubernetes).

## Deploying InfluxDB on Kubernetes

1. You can find the latest files in the Ondat use cases repository
   ```bash
   git clone https://github.com/storageos/use-cases.git storageos-usecases
   cd storageos-usecases
   ```

   StatefulSet definition:

   ```yaml
   apiVersion: apps/v1
   kind: StatefulSet
   metadata:
     name: influxdb
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: influxdb
     serviceName: influxdb
     ...
       spec:
         serviceAccountName: influxdb
           ...
           volumeMounts:
           - mountPath: /var/lib/influxdb
             name: data
         ...
     volumeClaimTemplates:
     - metadata:
         name: data
       spec:
         accessModes: ["ReadWriteOnce"]
         storageClassName: "storageos" # Ondat storageClass
         resources:
           requests:
             storage: 20Gi
   ```
   This excerpt is from the StatefulSet definition. This file contains the
   VolumeClaimTemplate that will dynamically provision storage, using the
   Ondat storage class. Dynamic provisioning occurs as a volumeMount has
   been declared with the same name as a VolumeClaim.

1. Create the InfluxDB objects

   ```bash
   kubectl create -f ./influxdb
   ```

2. Confirm InfluxDB is up and running.

   ```bash
   $ kubectl get pods
   NAME                    READY    STATUS     RESTARTS   AGE
   influxdb-client         1/1      Running    0          1m
   influxdb-0              1/1      Running    0          1m
   ```

3. Connect to the InfluxDB client pod, then to the InfluxDB server
   through the service (this reflects the common kubernetes pattern of
   maintaining a client pod to conveniently inspect a resource interactively).
   The default user (<em>admin</em>) and password (<em>admin</em>) are defined
   in the StatefulSet.

   ```bash
   $ kubectl exec -it influxdb-client -- bash
   root@influxdb-client:/# influx -host influxdb-0.influxdb
   Connected to http://influxdb-0.influxdb:8086 version 1.8.2
   InfluxDB shell version: 1.8.2
   > auth
   username: admin
   password: 
   > show databases
   name: databases
   name
    _internal

   > CREATE DATABASE weather;
   > USE weather
   Using database weather
   > INSERT temperature,location=London value=26.4
   > INSERT temperature,location=London value=24.9
   > INSERT temperature,location=London value=22.2
   > INSERT temperature,location=London value=14.7
   > INSERT temperature,location=London value=19.5
   > INSERT temperature,location=Paris value=27.1
   > INSERT temperature,location=Paris value=27.5
   > INSERT temperature,location=Paris value=21.3
   > INSERT temperature,location=Paris value=26.7
   > INSERT temperature,location=Paris value=30.0
   > SELECT MEAN(*) FROM "temperature" GROUP BY "location"
   name: temperature
   tags: location=London
   time mean_value

   0    25.65

   name: temperature
   tags: location=Paris
   time mean_value

   0    26.90
   ```

In the above steps we have inserted some time series data on the temperature
at two locations, and calculated the mean for both. InfluxDB offers a variety
of such aggregations (see the docs
[here](https://docs.influxdata.com/influxdb/v1.8/query_language/)), allowing
convenient analysis of time series data.

## Configuration

If you need custom startup options, you can edit or add to the environment
variables within the `20-statefulset.yaml` file.

## Backups

In this example of how to perform backups of an InfluxDB database on a
Kubernetes cluster, we write the output backup file
to an Amazon Web Services (AWS) S3 bucket. Other approaches, such as backing
up to internal servers or other Ondat volumes, are possible. For this
example to run successfully, Base64-encoded AWS credentials and an S3 bucket
name should be inserted into the data field of the
`backup/50-secret-config.yaml` file. 

```bash
$ echo -n '<your-aws-access-key-id>' | base64
XXXXXXXXXXXX
$ echo -n '<your-aws-secret-access-key>' | base64
XXXXXXXXXXXX
$ echo -n '<your-aws-default-region>' | base64
XXXXXXXXXXXX
$ echo -n '<your-S3-bucket-name>' | base64
XXXXXXXXXXXX
```

Secret definition:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backup-pod-environment
type: Opaque
data:
  AWS_ACCESS_KEY_ID: XXXXXXXXXXXX
  AWS_SECRET_ACCESS_KEY: XXXXXXXXXXXX
  AWS_DEFAULT_REGION: XXXXXXXXXXXX
  BUCKET_NAME: XXXXXXXXXXXX
  DB_NAME: d2VhdGhlcg==
  DB_HOST: aW5mbHV4ZGItMC5pbmZsdXhkYjo4MDg4
```

To perform the backup, create the secret and job from the manifest files
in the `backup` directory.

```bash
kubectl create -f ./influxdb/backup/
```

Confirm that the backup pod has been created, and the backup performed successfully.

```bash
NAME           READY   STATUS      RESTARTS   AGE
backup-ks976   0/1     Completed   0          1m
client         1/1     Running     0          10m
influxdb-0     1/1     Running     0          10m
mysql-0        1/1     Running     0          10m
```

The files generated by the backup operation should now be available in you S3
bucket. Re-perform the operation at any time by deleting and re-creating
the backup job.

```bash
$ kubectl delete -f "influxdb/40-backup-job.yaml"
job.batch "backup" deleted
$ kubectl create -f "influxdb/40-backup-job.yaml"
job.batch/backup created
```
