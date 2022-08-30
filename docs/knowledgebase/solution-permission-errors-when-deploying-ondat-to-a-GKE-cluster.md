---
title: "Solution - Troubleshooting Permission Errors When Deploying Ondat On A GKE Cluster"
linkTitle: "Solution - Troubleshooting Permission Errors When Deploying Ondat On A GKE Cluster"
---
## Issue

When attempting to deploy Ondat onto a new [GKE cluster](/docs/install/gcp/google-kubernetes-engine-gke/) with the [Ondat kubectl plugin](/docs/reference/kubectl-plugin/), you experience a permission error message that causes the installation to fail.

```bash
# installing Ondat using the Ondat kubectl plugin
kubectl storageos install \
  --include-etcd \
  --admin-username "storageos" \
  --admin-password "storageos"

# log output
namespace/storageos-etcd created
Warning: resource namespaces/storageos is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by  apply.  apply should only be used on resources created declaratively by either  create --save-config or  apply. The missing annotation will be patched automatically.
namespace/storageos configured
customresourcedefinition.apiextensions.k8s.io/etcdbackups.etcd.improbable.io created
customresourcedefinition.apiextensions.k8s.io/etcdbackupschedules.etcd.improbable.io created
customresourcedefinition.apiextensions.k8s.io/storageosclusters.storageos.com created
customresourcedefinition.apiextensions.k8s.io/etcdclusters.etcd.improbable.io created
customresourcedefinition.apiextensions.k8s.io/etcdpeers.etcd.improbable.io created
serviceaccount/storageos-operator created
customresourcedefinition.apiextensions.k8s.io/etcdrestores.etcd.improbable.io created
service/storageos-etcd-proxy created
deployment.apps/storageos-etcd-controller-manager created
configmap/storageos-operator created
configmap/storageos-related-images created
deployment.apps/storageos-etcd-proxy created
service/storageos-operator created
service/storageos-operator-webhook created
deployment.apps/storageos-operator created
validatingwebhookconfiguration.admissionregistration.k8s.io/storageos-operator-validating-webhook created

Error: Multiple errors:
[error when creating "manifestString": roles.rbac.authorization.k8s.io is forbidden: User "jane@example.com" cannot create resource "roles" in API group "rbac.authorization.k8s.io" in the namespace "storageos-etcd": requires one of ["container.roles.create"] permission(s)., error when creating "manifestString": clusterroles.rbac.authorization.k8s.io is forbidden: User "jane@example.com" cannot create resource "clusterroles" in API group "rbac.authorization.k8s.io" at the cluster scope: requires one of ["container.clusterRoles.create"] permission(s)., error when creating "manifestString": rolebindings.rbac.authorization.k8s.io is forbidden: User "jane@example.com" cannot create resource "rolebindings" in API group "rbac.authorization.k8s.io" in the namespace "storageos-etcd": requires one of ["container.roleBindings.create"] permission(s)., error when creating "manifestString": clusterrolebindings.rbac.authorization.k8s.io is forbidden: User "jane@example.com" cannot create resource "clusterrolebindings" in API group "rbac.authorization.k8s.io" at the cluster scope: requires one of ["container.clusterRoleBindings.create"] permission(s).]
[error when creating "manifestString": clusterroles.rbac.authorization.k8s.io is forbidden: User "jane@example.com" cannot create resource "clusterroles" in API group "rbac.authorization.k8s.io" at the cluster scope: requires one of ["container.clusterRoles.create"] permission(s)., error when creating "manifestString": clusterrolebindings.rbac.authorization.k8s.io is forbidden: User "jane@example.com" cannot create resource "clusterrolebindings" in API group "rbac.authorization.k8s.io" at the cluster scope: requires one of ["container.clusterRoleBindings.create"] permission(s).]
```

## Root Cause

- The permission error messages that are returned is due to not having the correct privileges to be able to install Ondat in a GKE cluster.
  - For more information how to manage permissions in GKE clusters, review the GKE documentation on how to [authorize actions in clusters using role-based access control](https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control).

## Resolution

- To resolve this issue, ensure that your user account has cluster administrator privileges first so that you can install Ondat successfully.

```bash
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$(gcloud config get-value account)
```
