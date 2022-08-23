---
title: "How To Get Your Ondat Cluster ID"
linkTitle: "How To Get Your Ondat Cluster ID"
---

## Overview

Every Ondat cluster has a unique cluster ID that is generated once an Ondat deployment is successfuly completed. In order for end users to be able to generate an Ondat licence and apply it to the cluster, an Ondat cluster ID is required.

## Prerequisites

- Ensure that you have successfully [installed Ondat](/docs/install/) into your Kubernetes or Openshift cluster.

## Procedure

### Step 1 - Install The Ondat CLI

- Deploy and run the [Ondat CLI utility as a deployment](https://docs.ondat.io/docs/reference/cli/#run-the-cli-as-a-deployment-in-your-cluster) first, so that you can interact and manage Ondat alongside  `kubectl`. Once deployed, obtain the Ondat CLI utility pod name for later reference.

  ```bash
  # Get the Ondat CLI utility pod name.
  kubectl --namespace=storageos get pod -ocustom-columns=_:.metadata.name --no-headers -lapp=storageos-cli
  
  storageos-cli-6958b7c4cd-nc8q5
  ```

### Step 2 - Locate The Ondat Cluster ID

- With the Ondat CLI deployed, you can run one of the following commands below to get the unique ID of the cluster.
  - The cluster ID will printed out as a UUID value with either a `ID` or `ClusterID` key.

  ```bash
  # Get cluster-wide information
  kubectl --namespace=storageos exec storageos-cli-6958b7c4cd-nc8q5 -- storageos get cluster

  ID:           ce7c9c90-896e-41d5-b823-27ed9a8d8c8f
  Created at:   2022-08-23T16:24:33Z (10 minutes ago)
  Updated at:   2022-08-23T16:24:33Z (10 minutes ago)
  Nodes:        5
    Healthy:    5
    Unhealthy:  0

  # Get more information about the licence status and unique cluster ID.
  kubectl --namespace=storageos exec storageos-cli-6958b7c4cd-nc8q5 -- storageos get licence

  ClusterID:      ce7c9c90-896e-41d5-b823-27ed9a8d8c8f
  Expiration:     2022-08-24T16:24:33Z (23 hours from now)
  Capacity:       50 GiB (53687091200)
  Used:           0 B (0)
  Kind:           unregistered
  Features:       []
  Customer name:
  ```

### Step 3 - Generate An Ondat Licence

- Note down the unique cluster ID so that it can be used to generate an Ondat licence through the [Ondat SaaS Platform](https://portal.ondat.io/) and apply it to your cluster so that it is successfully registered.
  - For information and guidance on how to generate and apply an Ondat licence to a cluster, review the [licensing documentation](/docs/operations/licensing/).
