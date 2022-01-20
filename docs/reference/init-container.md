---
title: "Init container"
linkTitle: Init container
---

Ondat has requirements for the configuration of host systems. As such,
Ondat starts an init container that sets the system configuration for
Ondat. The container also manages configuration changes required when
upgrading Ondat versions.

The container belongs to the DaemonSet that the [Ondat Cluster
Operator](/docs/reference/cluster-operator/_index.md) starts when a
`StorageOSCluster` resource is created. The `storageos-init` container is
executed as an
[initContainer](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
as part of a Kubernetes Pod. Therefore, only successful execution of the
`storageos-init` container processes will result in the main container
starting.

## Script Framework

The code responsible for fulfilling the requirements is based on a Script
Framework.

The script framework executes a set of scripts, performing checks,
verifications and other procedures needed for Ondat to be able to start.
The scripts stdout and stderr are written to the stdout and stderr of the init
app. The container logs contain all the logs of the individual scripts that
run. The exit statuses of the scripts are used to determine initialization
failure or success. Any non-zero exit status is logged as an event in the
Kubernetes Pod events.

If any of the scripts fail, the `storageos-init` container will propagate the
failure to Kubernetes, showing the status of the Pod as `Init:Err`.

To view the output of all `storageos-init` containers the following command can
be used:
```bash
kubectl -n storageos logs -l app=storageos,kind=daemonset -c storageos-init
```

For more details, check the 
[Ondat init container project](https://github.com/storageos/init).


## Scripts executed

The `storageos-init` container executes the following scripts.

- [enable-lio](https://github.com/storageos/init/tree/master/scripts/01-lio)
- [dbupgrade](https://github.com/storageos/init/tree/master/scripts/10-dbupgrade-v1v2)
