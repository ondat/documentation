---
title: "Troubleshooting"
linkTitle: Troubleshooting
---

This section is aimed to help you troubleshoot issues in your cluster, whether
they are related to the Ondat installation, integration with
orchestrators or common misconfigurations.

## Tools

To be able to troubleshoot issues the [Ondat CLI](/docs/reference/cli/_index) is required.

## Pod in pending because of mount error

### Issue:

The output of `kubectl describe pod $POD_ID` contains `no such file or
directory` and references the Ondat volume device file.

```bash
root@node1:~# kubectl -n kube-system describe $POD_ID
(...)
Events:
  (...)
  Normal   Scheduled         11s                default-scheduler  Successfully assigned default/d1 to node3
  Warning  FailedMount       4s (x4 over 9s)    kubelet, node3     MountVolume.SetUp failed for volume "pvc-f2a49198-c00c-11e8-ba01-0800278dc04d" : stat /var/lib/storageos/volumes/d9df3549-26c0-4cfc-62b4-724b443069a1: no such file or directory
```

### Reason:

There are two main reasons this issue may arise:
- The Ondat `DEVICE_DIR` location is wrongly configured when using Kubelet
  as a container
- Mount Propagation is not enabled


(Option 1) Misconfiguration of the DeviceDir/SharedDir

Some Kubernetes distributions such as Rancher, DockerEE or some installations
of OpenShift deploy the Kubelet as a container, because of this, the device
files that Ondat creates to mount into the containers need to be visible to
the kubelet. Ondat can be configured to share the device directory.

Modern installations use CSI, which handles the complexity internally.

### Assert:

```bash
root@node1:~# kubectl -n default describe stos | grep "Shared Dir"
  Shared Dir:      # <-- Shouldn't be blank
```

### Solution:

The Cluster Operator Custom Definition should specify the SharedDir option as follows.

```bash
spec:
  sharedDir: '/var/lib/kubelet/plugins/kubernetes.io~storageos' # Needed when Kubelet as a container
  ...
```

> 💡 See example on how to configure the [Ondat Custom
> Resource](/docs/reference/cluster-operator/examples/#specifying-a-shared-directory-for-use-with-kubelet-as-a-container).

&nbsp; <!-- this is a blank line -->

(Option 2) Mount propagation is not enabled.

> ⚠️ Applies only if Option 1 is configured properly.

### Assert:

**If not using the Kubelet as a container**, SSH into one of the nodes and check if
`/var/lib/storageos/volumes` is empty. If so, exec into any Ondat pod and
check the same directory.

```bash
root@node1:~# ls /var/lib/storageos/volumes/
root@node1:~#     # <-- Shouldn't be blank
root@node1:~# kubectl exec $POD_ID -c storageos -- ls -l /var/lib/storageos/volumes
bst-196004
d529b340-0189-15c7-f8f3-33bfc4cf03fa
ff537c5b-e295-e518-a340-0b6308b69f74
```

If the directory inside the container and the device files are visible,
disabled mount propagation is the cause.


**If using the Kubelet as a container**, SSH into one of the nodes and check if
`/var/lib/kubelet/plugins/kubernetes.io~storageos/devices` is empty. If
so, exec into any Ondat pod and check the same directory.

```bash
root@node1:~# ls /var/lib/kubelet/plugins/kubernetes.io~storageos/devices
root@node1:~#      # <-- Shouldn't be blank
root@node1:~# kubectl exec $POD_ID -c storageos -- ls -l /var/lib/kubelet/plugins/kubernetes.io~storageos/devices
bst-196004
d529b340-0189-15c7-f8f3-33bfc4cf03fa
ff537c5b-e295-e518-a340-0b6308b69f74
```

If the directory inside the container and the device files are visible,
disabled mount propagation is the cause.


### Solution:

Older versions of Kubernetes need to enable mount propagation as it is not
enabled by default. Most Kubernetes distributions allow MountPropagation to be
enabled using FeatureGates. Rancher specifically, needs to enable it in the
"View in API" section of your cluster. You need to edit the section
"rancherKubernetesEngineConfig" to enable the Kubelet feature gate.

## PVC pending state - Failed to dial Ondat

A created PVC remains in pending state making pods that need to mount that PVC
unable to start.

### Issue:
```bash
root@node1:~/# kubectl get pvc
NAME      STATUS        VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
vol-1     Pending                                                                            storageos       7s

kubectl describe pvc $PVC
(...)
Events:
  Type     Reason              Age               From                         Message
  ----     ------              ----              ----                         -------
  Warning  ProvisioningFailed  7s (x2 over 18s)  persistentvolume-controller  Failed to provision volume with StorageClass "storageos": Get http://storageos-cluster/version: failed to dial all known cluster members, (10.233.59.206:5705)
```

### Reason:
For non CSI installations of Ondat, Kubernetes uses the Ondat
API endpoint to communicate. If that communication fails, relevant actions such
as create or mount volume can't be transmitted to Ondat, hence the PVC
will remain in pending state. Ondat never received the action to perform,
so it never sent back an acknowledgement.

In this case, the Event message indicates that Ondat API is not responding,
implying that Ondat is not running. For Kubernetes to define Ondat pods
ready, the health check must pass.

### Assert:

Check the status of Ondat pods.

```bash
root@node1:~/# kubectl -n kube-system get pod --selector app=storageos # for CSI add --selector kind=daemonset
NAME              READY     STATUS    RESTARTS   AGE
storageos-qrqkj   0/1       Running   0          1m
storageos-s4bfv   0/1       Running   0          1m
storageos-vcpfx   0/1       Running   0          1m
storageos-w98f5   0/1       Running   0          1m
```

If the pods are not READY, the service will not forward traffic to the API they
serve hence PVC will remain in pending state until Ondat pods are
available.

> 💡 Kubernetes keeps trying to execute the action until it succeeds. If
> a PVC is created before Ondat finish starting, the PVC will be created
> eventually.

### Solution:
- Ondat health check takes 60 seconds of grace before reporting as READY.
  If Ondat is starting properly after that period, the volume will be
  created when Ondat finishes its bootstrap.
- If Ondat is not running or is not starting properly, the solution would
  be to troubleshoot the installation.



## PVC pending state - Secret Missing

A created PVC remains in pending state making pods that need to mount that PVC
unable to start.

### Issue: 
```bash
kubectl describe pvc $PVC
(...)
Events:
  Type     Reason              Age                From                         Message
  ----     ------              ----               ----                         -------
  Warning  ProvisioningFailed  13s (x2 over 28s)  persistentvolume-controller  Failed to provision volume with StorageClass "storageos": failed to get secret from ["storageos"/"storageos-api"]

```

### Reason:
For non CSI installations of Ondat, Kubernetes uses the Ondat
API endpoint to communicate. If that communication fails, relevant actions such
as create or mount a volume can't be transmitted to Ondat, and the PVC
will remain in pending state. Ondat never received the action to perform,
so it never sent back an acknowledgement.

The StorageClass provisioned for Ondat references a Secret from where it
retrieves the API endpoint and the authentication parameters. If that secret is
incorrect or missing, the connections won't be established. It is common to see
that the Secret has been deployed in a different namespace where the
StorageClass expects it or that is has been deployed with a different name.

### Assert:

1. Check the StorageClass parameters to know where the Secret is expected to be found.

    ```bash
    $ kubectl get storageclass storageos -o yaml

    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: storageos
    provisioner: csi.storageos.com
    allowVolumeExpansion: true
    parameters:
      csi.storage.k8s.io/fstype: ext4
      storageos.com/replicas: "1"
      csi.storage.k8s.io/secret-name: storageos-api
      csi.storage.k8s.io/secret-namespace: storageos
    ```

    > 💡 Note that the parameters specify `secret-namespace` and `secret-name`.

1. Check if the secret exists according to those parameters
    ```bash
    kubectl -n storageos get secret storageos-api
    No resources found.
    Error from server (NotFound): secrets "storageos-api" not found
    ```

    If no resources are found, it is clear that the Secret doesn't exist or it is not deployed in
    the right location.

### Solution:
Deploy Ondat following the [installation procedures](
/docs/introduction/quickstart). If you are using the manifests
provided for Kubernetes to deploy Ondat rather than using automated
provisioners, make sure that the StorageClass parameters and the Secret
reference match.

## Node name different from Hostname

#### Issue:
Ondat nodes can't join the cluster showing the following log entries.

```bash
time="2018-09-24T13:47:02Z" level=error msg="failed to start api" error="error verifying UUID: UUID aed3275f-846b-1f75-43a1-adbfec8bf974 has already been registered and has hostname 'debian-4', not 'node4'" module=command
```
### Reason:

The Ondat registration process to start the cluster uses the hostname of
the node where the Ondat container is running, provided by the Kubelet.
However, Ondat verifies the network hostname of the OS as a prestart check
to make sure it can communicate with other nodes. If those names don't match,
Ondat will be unable to start.

### Solution:

Make sure the hostnames match with the Kubernetes advertised names. If
you have changed the hostname of your nodes, make sure that you restart the
nodes to apply the change.


## Peer discovery - Networking

### Issue:
Ondat nodes can't join the cluster showing the following logs after one
minute of container uptime.

```bash
time="2018-09-24T13:40:20Z" level=info msg="not first cluster node, joining first node" action=create address=172.28.128.5 category=etcd host=node3 module=cp target=172.28.128.6
time="2018-09-24T13:40:20Z" level=error msg="could not retrieve cluster config from api" status_code=503
time="2018-09-24T13:40:20Z" level=error msg="failed to join existing cluster" action=create category=etcd endpoint="172.28.128.3,172.28.128.4,172.28.128.5,172.28.128.6" error="503 Service Unavailable" module=cp
time="2018-09-24T13:40:20Z" level=info msg="retrying cluster join in 5 seconds..." action=create category=etcd module=cp
```

### Reason:
Ondat uses a gossip protocol to discover nodes in the cluster. When
Ondat starts, one or more nodes can be referenced so new nodes can query
existing nodes for the list of members. This error indicates that the node
can't connect to any of the nodes in the known list. The known list is defined
in the `JOIN` variable.

### Assert:

It is likely that ports are block by a firewall.

SSH into one of your nodes and check connectivity to the rest of the nodes.
```bash
# Successfull execution:
[root@node06 ~]# nc -zv node04 5705
Ncat: Version 7.50 ( https://nmap.org/ncat  )
Ncat: Connected to 10.0.1.166:5705.
Ncat: 0 bytes sent, 0 bytes received in 0.01 seconds.
```

Ondat exposes network diagnostics in its API, viewable from the CLI.  To
use this feature, the CLI must query the API of a running node. The diagnostics
show information from all known cluster members. If all the ports are blocked
during the first bootstrap of the cluster, the diagnostics won't show any data
as nodes couldn't register.

> 💡 Ondat networks diagnostics are available for storageos-rc5 and
> storageos-cli-rc3 and above.

```bash
# Example:
root@node1:~# storageos cluster connectivity
SOURCE  NAME            ADDRESS            LATENCY      STATUS  MESSAGE
node4   node2.nats      172.28.128.4:5708  1.949275ms   OK
node4   node3.api       172.28.128.5:5705  3.070574ms   OK
node4   node3.nats      172.28.128.5:5708  2.989238ms   OK
node4   node2.directfs  172.28.128.4:5703  2.925707ms   OK
node4   node3.etcd      172.28.128.5:5707  2.854726ms   OK
node4   node3.directfs  172.28.128.5:5703  2.833371ms   OK
node4   node1.api       172.28.128.3:5705  2.714467ms   OK
node4   node1.nats      172.28.128.3:5708  2.613752ms   OK
node4   node1.etcd      172.28.128.3:5707  2.594159ms   OK
node4   node1.directfs  172.28.128.3:5703  2.601834ms   OK
node4   node2.api       172.28.128.4:5705  2.598236ms   OK
node4   node2.etcd      172.28.128.4:5707  16.650625ms  OK
node3   node4.nats      172.28.128.6:5708  1.304126ms   OK
node3   node4.api       172.28.128.6:5705  1.515218ms   OK
node3   node2.directfs  172.28.128.4:5703  1.359827ms   OK
node3   node1.api       172.28.128.3:5705  1.185535ms   OK
node3   node4.directfs  172.28.128.6:5703  1.379765ms   OK
node3   node1.etcd      172.28.128.3:5707  1.221176ms   OK
node3   node1.nats      172.28.128.3:5708  1.330122ms   OK
node3   node2.api       172.28.128.4:5705  1.238541ms   OK
node3   node1.directfs  172.28.128.3:5703  1.413574ms   OK
node3   node2.etcd      172.28.128.4:5707  1.214273ms   OK
node3   node2.nats      172.28.128.4:5708  1.321145ms   OK
node1   node4.directfs  172.28.128.6:5703  1.140797ms   OK
node1   node3.api       172.28.128.5:5705  1.089252ms   OK
node1   node4.api       172.28.128.6:5705  1.178439ms   OK
node1   node4.nats      172.28.128.6:5708  1.176648ms   OK
node1   node2.directfs  172.28.128.4:5703  1.529612ms   OK
node1   node2.etcd      172.28.128.4:5707  1.165681ms   OK
node1   node2.api       172.28.128.4:5705  1.29602ms    OK
node1   node2.nats      172.28.128.4:5708  1.267454ms   OK
node1   node3.nats      172.28.128.5:5708  1.485657ms   OK
node1   node3.etcd      172.28.128.5:5707  1.469429ms   OK
node1   node3.directfs  172.28.128.5:5703  1.503015ms   OK
node2   node4.directfs  172.28.128.6:5703  1.484ms      OK
node2   node1.directfs  172.28.128.3:5703  1.275304ms   OK
node2   node4.nats      172.28.128.6:5708  1.261422ms   OK
node2   node4.api       172.28.128.6:5705  1.465532ms   OK
node2   node3.api       172.28.128.5:5705  1.252768ms   OK
node2   node3.nats      172.28.128.5:5708  1.212332ms   OK
node2   node3.directfs  172.28.128.5:5703  1.192792ms   OK
node2   node3.etcd      172.28.128.5:5707  1.270076ms   OK
node2   node1.etcd      172.28.128.3:5707  1.218522ms   OK
node2   node1.api       172.28.128.3:5705  1.363071ms   OK
node2   node1.nats      172.28.128.3:5708  1.349383ms   OK
```
### Solution:
Open ports following the [prerequisites page](
/docs/prerequisites/firewalls).


## Peer discovery - Pod allocation

### Issue:
Ondat nodes can't join the cluster and show the following log entries.

```bash
time="2018-09-24T13:40:20Z" level=info msg="not first cluster node, joining first node" action=create address=172.28.128.5 category=etcd host=node3 module=cp target=172.28.128.6
time="2018-09-24T13:40:20Z" level=error msg="could not retrieve cluster config from api" status_code=503
time="2018-09-24T13:40:20Z" level=error msg="failed to join existing cluster" action=create category=etcd endpoint="172.28.128.3,172.28.128.4,172.28.128.5,172.28.128.6" error="503 Service Unavailable" module=cp
time="2018-09-24T13:40:20Z" level=info msg="retrying cluster join in 5 seconds..." action=create category=etcd module=cp
```

### Reason:
Ondat uses a gossip protocol to discover the nodes in the cluster. When
Ondat starts, one or more active nodes must be referenced so new nodes can
query existing nodes for the list of members. This error indicates that the node
can't connect to any of the nodes in the known list. The known list is defined
in the `JOIN` variable.

If there are no active Ondat nodes, the bootstrap process will elect the
first node in the `JOIN` variable as master, and the rest will try to
discover from it. In case of that node not starting, the whole cluster will
remain unable to bootstrap.

Installations of Ondat use a DaemonSet, and by default do not schedule
Ondat pods to master nodes, due to the presence of the
`node-role.kubernetes.io/master:NoSchedule` taint that is typically present. In
such cases the `JOIN` variable must not contain master nodes or the Ondat
cluster will remain unable to start.

### Assert:

Check that the first node of the `JOIN` variable started properly.

```bash
root@node1:~/# kubectl -n kube-system describe ds/storageos | grep JOIN
    JOIN:          172.28.128.3,172.28.128.4,172.28.128.5
root@node1:~/# kubectl -n kube-system get pod -o wide | grep 172.28.128.3
storageos-8zqxl   1/1       Running   0          2m        172.28.128.3   node1
```

### Solution:

Make sure that the `JOIN` variable doesn't specify the master nodes. In case
you are using the discovery service, it is necessary to ensure that the
DaemonSet won't allocate Pods on the masters. This can be achieved with taints,
node selectors or labels.

For installations with the Ondat operator you can specify which nodes to
deploy Ondat on using nodeSelectors. See examples in the [Cluster Operator
Examples
page](docs/reference/cluster-operator/examples/#installing-to-a-subset-of-nodes).

For more advanced installations using compute-only and storage nodes, check the
`storageos.com/deployment=computeonly` label that can be added to the nodes
through Kubernetes node labels, or Ondat in the [Labels](
/docs/reference/labels) page.

## LIO Init:Error

### Issue:

Ondat pods not starting with `Init:Error`
```bash
kubectl -n kube-system get pod
NAME              READY     STATUS              RESTARTS   AGE
storageos-2kwqx   0/3       Init:Err             0          6s
storageos-cffcr   0/3       Init:Err             0          6s
storageos-d4f69   0/3       Init:Err             0          6s
storageos-nhq7m   0/3       Init:Err             0          6s
```

### Reason:
This indicates that since the Linux open source SCSI drivers are not enabled,
Ondat cannot start. The Ondat DaemonSet enables the required kernel
modules on the host system. If you are seeing these errors it is because that
container couldn't load the modules.

### Assert
Check the logs of the init container.

```bash
kubectl -n kube-system logs $ANY_STORAGEOS_POD -c storageos-init
```

In case of failure, it will show the following output, indicating which kernel
modules couldn't be loaded or that they are not properly configured:

```bash
Checking configfs
configfs mounted on sys/kernel/config
Module target_core_mod is not running
executing modprobe -b target_core_mod
Module tcm_loop is not running
executing modprobe -b tcm_loop
modprobe: FATAL: Module tcm_loop not found.
```

### Solution:
Install the required kernel modules (usually found in the
`linux-image-extra-$(uname -r)` package of your distribution) on your nodes
following this [prerequisites page](
/docs/prerequisites/systemconfiguration) and delete Ondat
pods, allowing the DaemonSet to create the pods again.

## LIO not enabled

### Issue:
Ondat node can't start and shows the following log entries.

```bash
time="2018-09-24T14:34:40Z" level=error msg="liocheck returned error" category=liocheck error="exit status 1" module=dataplane stderr="Sysfs root '/sys/kernel/config/target' is missing, is kernel configfs present and target_core_mod loaded? category=fslio level=warn\nRuntime error checking stage 'target_core_mod': SysFs root missing category=fslio level=warn\nliocheck: FAIL (lio_capable_system() returns failure) category=fslio level=fatal\n" stdout=
time="2018-09-24T14:34:40Z" level=error msg="failed to start dataplane services" error="system dependency check failed: exit status 1" module=command
```

### Reason:
This indicates that one or more kernel modules required for Ondat are
not loaded.

### Assert
The following kernel modules must be enabled in the host.
```bash
lsmod  | egrep "^tcm_loop|^target_core_mod|^target_core_file|^configfs"
```

### Solution:
Install the required kernel modules (usually found in the
`linux-image-extra-$(uname -r)` package of your distribution) on your nodes
following this [prerequisites page](
/docs/prerequisites/systemconfiguration) and restart the container.




## (OpenShift) Ondat pods missing -- DaemonSet error

Ondat DaemonSet doesn't have any pod replicas. The DaemonSet couldn't
allocate any Pod due to security issues.

### Issue:
```bash
[root@master02 standard]# oc get pod
No resources found.
[root@master02 standard]# oc describe daemonset storageos
(...)
Events:
  Type     Reason        Age                From                  Message
  ----     ------        ----               ----                  -------
  Warning  FailedCreate  0s (x12 over 10s)  daemonset-controller  Error creating: pods "storageos-" is forbidden: unable to validate against any security context constraint: [provider restricted: .spec.securityContext.hostNetwork: Invalid value: true: Host network is not allowed to be used provider restricted: .spec.securityContext.hostPID: Invalid value: true: Host PID is not allowed to be used spec.volumes[0]: Invalid value: "hostPath": hostPath volumes are not allowed to be used spec.volumes[1]: Invalid value: "hostPath": hostPath volumes are not allowed to be used spec.volumes[2]: Invalid value: "hostPath": hostPath volumes are not allowed to be used spec.volumes[3]: Invalid value: "hostPath": hostPath volumes are not allowed to be used spec.initContainers[0].securityContext.privileged: Invalid value: true: Privileged containers are not allowed capabilities.add: Invalid value: "SYS_ADMIN": capability may not be added spec.initContainers[0].securityContext.hostNetwork: Invalid value: true: Host network is not allowed to be used spec.initContainers[0].securityContext.containers[0].hostPort: Invalid value: 5705: Host ports are not allowed to be used spec.initContainers[0].securityContext.hostPID: Invalid value: true: Host PID is not allowed to be used spec.containers[0].securityContext.privileged: Invalid value: true: Privileged containers are not allowed capabilities.add: Invalid value: "SYS_ADMIN": capability may not be added spec.containers[0].securityContext.hostNetwork: Invalid value: true: Host network is not allowed to be used spec.containers[0].securityContext.containers[0].hostPort: Invalid value: 5705: Host ports are not allowed to be used spec.containers[0].securityContext.hostPID: Invalid value: true: Host PID is not allowed to be used]
```

### Reason:

The OpenShift cluster has security context constraint policies enabled that
forbid any pod, without an explicitly set policy for the service account, to
be allocated.

### Assert:

Check if the Ondat ServiceAccount can create pods with enough permissions
```bash
oc get scc privileged -o yaml # Or custom scc with enough privileges
(...)
users:
- system:admin
- system:serviceaccount:openshift-infra:build-controller
- system:serviceaccount:management-infra:management-admin
- system:serviceaccount:management-infra:inspector-admin
- system:serviceaccount:storageos:storageos                       <--
- system:serviceaccount:tiller:tiller
```

If the Ondat sa system:serviceaccount:storageos:storageos is in the
privileged scc it will be able to create pods.

### Solution:

Add the ServiceAccount system:serviceaccount:storageos:storageos to a scc with
enough privileges.

```bash
oc adm policy add-scc-to-user privileged system:serviceaccount:storageos:storageos
```

## Getting Help

If our troubleshooting guides do not help resolve your issue, see our
[support section](/docs/support) for details on how
to get in touch with us.
