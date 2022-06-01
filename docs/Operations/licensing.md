---
title: "Licensing"
linkTitle: Licensing
---

# Overview

This document will walk you through how to request an Ondat license for your cluster, and what types of licenses can be requested.

You will need a license for Ondat if you want to make use of the full functionalities of our product. The cluster will run unlicensed for 24 hours, but after this time period, any new operations will be blocked. You can unlock the normal functioning of the cluster by applying a valid license to the cluster.

# Types of Licenses

## Free Trial

You can use Ondat for free without any restrictions for 1 month.

## Free Forever

You can use Ondat for free without any time limit with a 1 TB usable capacity and up to 3 nodes.

## Enterprise Premium

You can obtain a tailor-made license suitable for your needs with premium features. For more information, contact hello@ondat.io or message us via Intercom.

You can also book a demo with our customer success team [here](https://www.ondat.io/request-demo).

# Obtaining a License

## Procedure

## Step 1 - Register on the Ondat SaaS Platform

You need to register yourself on the [Ondat SaaS Platform](https://portal.ondat.io/signup) in order to retrieve your license.

## Step 2 - Generate a License

1. Go to the “Organization” tab on the menu bar
1. Click on “Generate a New License”
1. Choose the cluster you want to add a license to

  > NOTE: If you don't have a cluster connected to the portal you can generate a licence just by using the `clusterId`

  > NOTE: To obtain your `clusterId`, follow the steps [here](/docs/operations/cluster-id/)

1. Choose the type of license you want the cluster to use
1. Click generate
1. Copy the command shown on the the modal

## Step 3 - Add license to the cluster

1. Run the CLI command that you have copied on your machine
1. Congratulations, you have successfully applied the license to your cluster!

# Further Reading: Manage Your License in CLI

## Running the Ondat CLI

### Step 1 - Launch target Kubernetes Cluster

1. In order to get the CLI running, you must launch it on the target Kubernetes cluster.

> ⚠️ Be sure to edit the environment variables appropriately for your target cluster, eg. the username/password for the administrative user.

  ```shell
  kubectl -n storageos create -f-<<END
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: storageos-cli
    namespace: storageos
    labels:
      app: storageos
      run: cli
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: storageos-cli
        run: cli
    template:
      metadata:
        labels:
          app: storageos-cli
          run: cli
      spec:
        containers:
        - command:
          - /bin/sh
          - -c
          - "while true; do sleep 3600; done"
          env:
          - name: STORAGEOS_ENDPOINTS
            value: http://storageos:5705
          - name: STORAGEOS_USERNAME
            value: storageos
          - name: STORAGEOS_PASSWORD
            value: storageos
          image: storageos/cli:v2.5.0
          name: cli
  END
  ```

### Step 2 - Retrieve Unique Identifier

Once the pod is launched, run the following script:

```shell
POD=$(kubectl -n storageos get pod -ocustom-columns=_:.metadata.name --no-headers -lapp=storageos-cli)
```

Now that the `POD` variable is set, the pod is accessible via that variable for the rest of the lifetime of that terminal.

> Note: If you open a new terminal, you'll need to run this command again to rediscover the ID of the pod.

## Retrieving a cluster ID via the Ondat CLI

### Prerequisites

> ⚠️ You need to have Ondat CLI running - see [instructions](/docs/operations/licensing/#running-the-ondat-cli)

> 💡 For more information refer to the licence
[CLI command](/docs/reference/cli) reference documentation.

### Procedure

1. Run the following command

    ```shell
    kubectl -n storageos exec $POD -- storageos get cluster
    ```

1. You will see the following message:

    ```
    ID:           704dd165-9580-4da4-a554-0acb96d328cb
    Created at:   2022-01-10T13:58:00Z (2 weeks ago)
    Updated at:   2022-01-10T14:05:27Z (2 weeks ago)
    Nodes:        3
      Healthy:    3
      Unhealthy:  0
    ```

The UUID in the `ID` field is unique to your cluster and is the only information you need in order to obtain your first license.

## View your license details on the CLI

A license contains a list of capabilities and capacities, the cluster ID, an expiry time, any extra features and a license type alongside a digital signature.

### Prerequisites

> ⚠️ You need to have Ondat CLI running - see [instructions](/docs/operations/licensing/#running-the-ondat-cli)
> 💡 For more information refer to the licence
[CLI command](/docs/reference/cli) reference documentation.

### Procedure

1. Run the following command to view the license details

    ```shell
    cat license.dat
    ```

1. The following message will appear

    ```
    clusterCapacityGiB: 5120 
    clusterID: 164237eb-f88a-4bb8-a7cf-a23d468e07c0 
    customerName: storageos
    expiresAt: "2021-11-15T14:00:00Z" 
    features:
    - nfs
    kind: project
    ------------- LICENCE SIGNATURE -------------
    KyjNleTcdmieZVLmZ/rg0SzdAM7I/CH0j22FIFJJSJaeB71OvQrTMtHGyL5TSFNMrEGbyh1HQlDgZb5A
    V1HyjBlS3LjoB/MoagulTxIlZh/R8eRXCOQ46qNZ8Yb7+dHLdCVXBnRqZT11hLqZsMqIeO1y9f5dw65H
    kvl6vWW7YIS9r655S25jMMU7brrGDQVdjvU7tSA74BrnzDFHu7/poopIuFqcxZc/NLrKp/akkvyZI5Ex
    1wH7D4onjVG2pgi30Kia+mjbI1B9pxQyRppQQ4hNXy4qBUUNMFh0menh0wHdQoM1VLU4Il22PrkeICV0
    NaalLsK/96bJov6tpbg96g==
    ```

## Ondat CLI - Applying a licence via the CLI

This information is only applicable if you have received a license file from our Customer Success team. Otherwise, you should receive and install your license via the [Ondat SaaS Platform](https://portal.ondat.io/).

### Prerequisites

> ⚠️ You need to have Ondat CLI running - see [instructions](/docs/operations/licensing/#running-the-ondat-cli)

> ⚠️ Make sure POD variable is set as per the CLI instructions

> ⚠️ You need to have received a license from our Customer Success team. Contct hello@ondat.io for more details.

> 💡 For more information refer to the licence
[CLI command](/docs/reference/cli) reference documentation.

### Procedure

#### Step 1 - Apply license key

Run the following command to apply the licence key stored in `/path/to/storageos-licence.dat`

```shell
cat /path/to/storageos-license.dat | kubectl -n storageos exec -it $POD -- storageos apply license --from-stdin
```

#### Step 2 - Check for extra features

Run the following command to check for extra featurs provided by your latest license:

```shell
kubectl -n storageos exec $POD -- storageos get license
```

You will see the message below:

```
ClusterID:      033a4774-c18f-4d05-ba86-90b818957f34
Expiration:     2024-01-01T23:59:59Z (2 years from now)
Capacity:       15 TiB (16520591704064)
Used:           0 B (0)
Kind:           standard
Features:       [nfs]
Customer name:  Sally Forth
```

> 💡 Don't worry if you don't see all of these fields - some of them are only visible when they are relevant to your individual license.
