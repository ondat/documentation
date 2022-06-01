---
title: "MySQL"
linkTitle: MySQL
---

![image](/images/docs/explore/mysqllogo.png)

MySQL is a popular SQL open source database for a wide range of popular
web-based applications including WordPress.

Before you start, ensure you have Ondat installed and ready on a Kubernetes
cluster. [See our guide on how to install Ondat on Kubernetes for more
information](/docs/install/kubernetes).

## Deploying MySQL on Kubernetes

1. You can find the latest files in the Ondat use cases repository

   ```bash
   git clone https://github.com/storageos/use-cases.git storageos-usecases
   ```

   StatefulSet defintion

   ```yaml
   apiversion: apps/v1
   kind: statefulset
   metadata:
    name: mysql
   spec:
    selector:
      matchlabels:
        app: mysql
        env: prod
    servicename: mysql
    replicas: 1
    ...
    spec:
        serviceaccountname: mysql
         ...
         volumemounts:
          - name: data
            mountpath: /var/lib/mysql
            subpath: mysql
          - name: conf
            mountpath: /etc/mysql/mysql.conf.d
      ...
   volumeclaimtemplates:
    - metadata:
        name: data
        labels:
          env: prod
      spec:
        accessmodes: ["readwriteonce"]
        storageclassname: "storageos"
        resources:
          requests:
            storage: 5gi
   ```

   This excerpt is from the StatefulSet definition. This file contains the
   VolumeClaim template that will dynamically provision storage, using the
   Ondat storage class. Dynamic provisioning occurs as a volumeMount has
   been declared with the same name as a VolumeClaim.

1. Move into the MySQL examples folder and create the objects

   ```bash
   cd storageos-usecases
   kubectl create -f ./mysql
   ```

1. Confirm MySQL is up and running.

   ```bash
   $ kubectl get pods -w -l app=mysql
   NAME        READY    STATUS    RESTARTS    AGE
   mysql-0     1/1      Running    0          1m
   ```

1. Connect to the MySQL client pod and connect to the MySQL server through the
   service

   ```bash
   $ kubectl exec client -- mysql -h mysql-0.mysql -e "show databases;"
   Database
   information_schema
   mysql
   performance_schema
   ```

## Configuration

If you need custom startup options, you can edit the ConfigMap file
[15-mysqld-configmap.yaml](https://github.com/storageos/use-cases/blob/master/mysql/15-mysqld-configmap.yaml)
with your desired MySQL configuration settings.
