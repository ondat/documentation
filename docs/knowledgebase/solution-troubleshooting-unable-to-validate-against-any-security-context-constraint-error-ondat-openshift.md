---
title: "Solution - Troubleshooting 'unable to validate against any security context constraint' Error When Deploying Ondat In OpenShift"
linkTitle: "Solution - Troubleshooting 'unable to validate against any security context constraint' Error When Deploying Ondat In OpenShift"
---

## Issue

When attempting to deploy Ondat into an OpenShift cluster, you notice that Ondat daemonset pods are missing in the project where Ondat is supposed to reside in. Below is the example of the `Events:` error message that shows up when you investigate further into why the daemonset is not running:

```bash
# Get the status of the pods in the "storageos" project.
oc get pods

No resources found.

# Describe the Ondat daemonset  in the "storageos" project.
oc describe daemonset storageos

# Truncated output.
Events:
  Type     Reason        Age                From                  Message
  ----     ------        ----               ----                  -------
  Warning  FailedCreate  0s (x12 over 10s)  daemonset-controller  Error creating: pods "storageos-" is forbidden: unable to validate against any security context constraint: [provider restricted: .spec.securityContext.hostNetwork: Invalid value: true: Host network is not allowed to be used provider restricted: .spec.securityContext.hostPID: Invalid value: true: Host PID is not allowed to be used spec.volumes[0]: Invalid value: "hostPath": hostPath volumes are not allowed to be used spec.volumes[1]: Invalid value: "hostPath": hostPath volumes are not allowed to be used spec.volumes[2]: Invalid value: "hostPath": hostPath volumes are not allowed to be used spec.volumes[3]: Invalid value: "hostPath": hostPath volumes are not allowed to be used spec.initContainers[0].securityContext.privileged: Invalid value: true: Privileged containers are not allowed capabilities.add: Invalid value: "SYS_ADMIN": capability may not be added spec.initContainers[0].securityContext.hostNetwork: Invalid value: true: Host network is not allowed to be used spec.initContainers[0].securityContext.containers[0].hostPort: Invalid value: 5705: Host ports are not allowed to be used spec.initContainers[0].securityContext.hostPID: Invalid value: true: Host PID is not allowed to be used spec.containers[0].securityContext.privileged: Invalid value: true: Privileged containers are not allowed capabilities.add: Invalid value: "SYS_ADMIN": capability may not be added spec.containers[0].securityContext.hostNetwork: Invalid value: true: Host network is not allowed to be used spec.containers[0].securityContext.containers[0].hostPort: Invalid value: 5705: Host ports are not allowed to be used spec.containers[0].securityContext.hostPID: Invalid value: true: Host PID is not allowed to be used]

```

## Root Cause

The root cause of this issue is due to the default [Security Context Constraints (SCCs)](https://docs.openshift.com/container-platform/latest/authentication/managing-security-context-constraints.html) polices in your OpenShift cluster. By default, the polices forbid any pod without an explicitly, defined policy for the [`ServiceAccount`](https://docs.openshift.com/container-platform/4.11/authentication/understanding-and-creating-service-accounts.html) used by Ondat.

## Resolution

1. Check and ensure that the Ondat `ServiceAccount` has the correct permissions to be able to successfully create objects.

```bash
# Get more information about the ServiceAccounts that are under the "privileged" SCC.
oc get scc privileged --output yaml

# Truncated output.
users:
- system:admin
- system:serviceaccount:openshift-infra:build-controller
- system:serviceaccount:management-infra:management-admin
- system:serviceaccount:management-infra:inspector-admin
- system:serviceaccount:tiller:tiller
```

2. If Ondat's `ServiceAccount`  >> `system:serviceaccount:storageos:storageos` does not show up as demonstrated in in the command above, the next step will be to add the `ServiceAccount` to the `privileged` SCC as demonstrated below:

```bash
# Add Ondat ServiceAccount to the "privileged" SCC.
oc adm policy add-scc-to-user privileged system:serviceaccount:storageos:storageos
```

## References

- [Managing security context constraints - OpenShift Documentation](https://docs.openshift.com/container-platform/latest/authentication/managing-security-context-constraints.html)
- [Understanding and creating service accounts - OpenShift Documentation](https://docs.openshift.com/container-platform/4.11/authentication/understanding-and-creating-service-accounts.html)
