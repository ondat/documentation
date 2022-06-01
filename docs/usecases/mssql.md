---
title: "MS SQL"
linkTitle: MS SQL
---

![mssqllogo](/images/docs/explore/mssql.png)

Beginning with Microsoft SQL Server 2017, Microsoft has supported MSSQL on
linux.

Before you start, ensure you have Ondat installed and ready on a Kubernetes
cluster. [See our guide on how to install Ondat on Kubernetes for more
information](/docs/install/kubernetes).

## Deploying MS SQL on Kubernetes

1. You can find the latest files in the Ondat use cases repository

   ```bash
   git clone https://github.com/storageos/use-cases.git storageos-usecases
   ```

   StatefulSet defintion

   ```yaml
   kind: StatefulSet
   metadata:
    name: mssql
   spec:
    selector:
      matchLabels:
        app: mssql
        env: prod
    serviceName: mssql
    replicas: 1
    ...
    spec:
        serviceAccountName: mssql
         ...
         volumeMounts:
          - name: data
            mountPath: /var/opt/mssql
      ...
   volumeClaimTemplates:
    - metadata:
        name: data
        labels:
          env: prod
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "storageos" # Ondat storageClass 
        resources:
          requests:
            storage: 5Gi
   ```

   This excerpt is from the StatefulSet definition. This file contains the
   VolumeClaim template that will dynamically provision storage, using the
   Ondat storage class. Dynamic provisioning occurs as a volumeMount has
   been declared with the same name as a VolumeClaim.

1. Move into the MS SQL examples folder and create the objects

   ```bash
   cd storageos-usecases
   kubectl create -f ./mssql
   ```

1. Confirm MS SQL is up and running.

   ```bash
   $ kubectl get pods -w -l app=mssql
   NAME        READY    STATUS    RESTARTS    AGE
   mssql-0     1/1      Running    0          1m
   ```

1. Connect to the MS SQL client pod and connect to the MS SQL server through the
   service

   ```bash
    $ kubectl exec -it mssql-0 -- /opt/mssql-tools/bin/sqlcmd -S mssql-0.mssql -U SA -P 'Password15'
    1> USE master;
    2> GO
    Changed database context to 'master'.
    1> SELECT name, database_id, create_date FROM sys.databases ;
    2> GO
    name                        database_id create_date            
    --------------------------- ----------- -----------------------
    master                                1 2003-04-08 09:13:36.390
    tempdb                                2 2018-11-02 16:30:37.907
    model                                 3 2003-04-08 09:13:36.390
    msdb                                  4 2018-10-19 01:18:57.300

    (4 rows affected)
    ```

## Configuration

If you need custom startup options, you can edit the ConfigMap file
[15-mssql-configmap.yaml](https://github.com/storageos/use-cases/blob/master/mssql/15-mssql-configmap.yaml)
with your desired MS SQL configuration settings.
