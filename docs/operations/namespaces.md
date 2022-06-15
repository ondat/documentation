---
title: "Namespaces"
linkTitle: Namespaces
---

Namespaces help different projects or teams share an Ondat cluster. Only the
default namespace is created by default.

Namespaces apply to volumes.

## Managing Namespaces

In order to create a new namespace navigate to "Namespaces" in the GUI, and
select "Create Namespace".

When a Kubernetes PVC is created in a namespace, Ondat automatically maps
the Volume in the same namespace. Namespaces are created by Ondat to fulfil
the RBAC rules enforced by Kubernetes roles.

In order to delete a namespace, all volumes must be deleted from the namespace
before the namespace can be deleted.
