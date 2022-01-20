---
title: "PID Limits"
linkTitle: PID Limits
weight: 400
---

Ondat recommends that a [PID
cgroup](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html#pid)
limit of 32768 be used for Ondat pods.

> Most environments fulfill this prerequisite by default. Check the
> Ondat init container logs as shown below to ensure this is the case.

Ondat pods running in Kubernetes are part of a PID cgroup that may limit
the maximum number of PIDs that all containers in the PID cgroup slice can
spawn. As the Linux kernel assigns a PID to processes and Light Weight
Processes (LWP) a low limit can be easily reached under certain circumstances.
The PID limit can be set by the Kubernetes distribution or by the container
runtime. Generally the limit is set to the machine wide default limit of 32768
but some environments can set this as low as 1024. A low PID limit may prevent
Ondat from spawning the required threads.

The [Ondat init container](https://github.com/storageos/init) runs a script
that checks for the PID limit of the PID cGroup slice that the Ondat pod
runs in. If the
[script](https://github.com/storageos/init/blob/master/scripts/02-limits/limits.sh)
finds that the limit is less than 32768 it will log a warning. This warning can
be viewed using kubectl to check the init container logs.

```bash
$ kubectl -n storageos logs -l app.kubernetes.io/component=control-plane,app=storageos -c init
WARNING: Effective max.pids limit (1024) less than RECOMMENDED_MAX_PIDS_LIMIT (32768)
```

## Setting a Kubernetes PID limit

Kubernetes defaults to an unlimited `PodPidsLimit`, which results in the usage of
the machine wide limit; typically 32768.

For information on how to configure the Kubernetes PID limit see the Kubernetes
documentation
[here](https://kubernetes.io/docs/tasks/administer-cluster/kubelet-config-file/).

## Setting a CRI-O PID limit

Certain orchestrators or setups use CRI-O as the container runtime. Openshift
4.x currently has CRI-O set a PID limit of 1024 by default. To configure the
default CRI-O limit in Openshift 4.x see the RedHat documentation
[here](https://access.redhat.com/solutions/5305611). To configure CRI-O more
generally see the CRI-O documentation
[here](https://github.com/cri-o/cri-o/blob/master/docs/crio.conf.5.md).
