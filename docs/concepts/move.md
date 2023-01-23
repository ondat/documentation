---
title: "Move"
linkTitle: "Move"
weight: 1
---

## Moving Ondat volume deployments

A volume deployment (replica or primary) can be moved freely between nodes, this can be extremely useful in specific scenarios, and it's available through a new command in the command-line tool.

It can be used to manually re-balance the cluster, reduce load on over-loaded nodes, etc.

## Example of use

Here's an example of how the CLI command works:

```bash
storageos update volume move my-volume-id source-node-id destination-node-id --namespace my-namespace-name --timeout 30m
```

## Large volumes

Syncing large volumes can take a long time depending on the amount of data and cluster's technical specifications (disks, bandwidth, etc) thus we recommended the use of a long timeout for this operation.

The global `timeout` flag is available for all commands.

## Moving to where a deployment already exists

When attempting to move a volume master deployment into a node that already houses a replica, we'll instead attempt to promote that replica to a primary thus swapping roles.

⚠️ Nothing will happen when trying to move a volume replica deployment into another replica as there's no functional distinction between these two.

## Safety first

The process is safe to use and only ever removes data when a new deployment has been synced within the new node.
