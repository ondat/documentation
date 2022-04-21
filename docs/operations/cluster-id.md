---
title: "Obtain a ClusterID"
linkTitle: Obtain a ClusterID
---

Every Ondat cluster has a unique ClusterID generated at bootstrap. An Ondat Licence is specific for a ClusterID.

## How to obtain the ClusterID

You can obtain the ClusterID using the CLI.

This CLI command can print the cluster ID:

```bash
$ storageos get cluster
ID:               704dd165-9580-4da4-a554-0acb96d328cb
Licence:
  expiration:     2021-03-25T13:48:46Z (1 year from now)
  capacity:       5.0 TiB
  kind:           professional
  customer name:  storageos
Created at:       2020-03-25T13:48:33Z (1 hour ago)
Updated at:       2020-03-25T13:48:46Z (1 hour ago)
```

Given the Cluster ID, you can generate a license on the [SaaS Platform](https://portal.ondat.io/) following [this procedure](/docs/operations/licensing/#procedure).
