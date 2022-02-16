---
title: "ClusterID"
linkTitle: ClusterID
---

Every Ondat cluster has a unique ClusterID generated at bootstrap. A
Ondat Licence is specific for a ClusterID.

## How to obtain the ClusterID

You can obtain the ClusterID using either the CLI or GUI.

### GUI

You will need access to the Ondat GUI on port 5705 of any of your nodes.
For convenience, it is often easiest to port forward the service using the
following kubectl incantation (this will block, so a second terminal window may
be advisable):

  ```bash
  kubectl port-forward -n storageos svc/storageos 5705
  ```

As an alternative, an Ingress controller may be preferred.

Once you have obtained access to the GUI, login using whatever credentials you
used to create the cluster and go to the "Licence" section on the left
navigation menu.

![Licence page](/images/docs/operations/licensing/licence-page.png)

### CLI

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

Given the Cluster ID, the Ondat team can generate a licence.
