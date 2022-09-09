---
title: "Solution - Troubleshooting 'UUID has already been registered and has hostname' Error"
linkTitle: "Solution - Troubleshooting 'UUID has already been registered and has hostname' Error"
---

## Issue

Ondat nodes cannot successfully join the cluster due to the following error message >> `error verifying UUID: UUID aed3275f-846b-1f75-43a1-adbfec8bf974 has already been registered and has hostname 'debian-4', not 'node4'` as demonstrated in the log entry below;

```bash
# Truncated output.
time="2018-09-24T13:47:02Z" level=error msg="failed to start api" error="error verifying UUID: UUID aed3275f-846b-1f75-43a1-adbfec8bf974 has already been registered and has hostname 'debian-4', not 'node4'" module=command
```

## Root Cause

The Ondat registration process to start the cluster uses the **hostname** of the node where the Ondat container is running, provided by the [kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/).

- However, Ondat verifies the network hostname of the OS as a preflight check to make sure it can communicate with other nodes. If those names don’t match, Ondat will be unable to start.

## Resolution

Ensure that the hostnames match with the names advertised by your Kubernetes cluster.

- If you have changed the hostname of your nodes, ensure that you restart the nodes for changes to be applied successfully.
