---
title: "Topology-Aware Placement (TAP)"
linkTitle: Topology-Aware Placement (TAP)
---

Ondat Topology-Aware Placement is a feature that enforces placement of data
across failure domains to guarantee high availability.

TAP uses default labels on nodes to define failure domains. For instance, an
Availability Zone. However, the key label used to segment failure domains can
be defined by the user per node. Also, TAP is an opt in feature per volume. The
following guide demonstrates how to use topology-aware placement. We will
enable Topology-Aware Placement on a PVC, set it to the `soft` Failure Mode.

## HowTo enable TAP per volume

> 💡 Labels can be applied to a PVC directly, or indirectly by adding them
> as parameters on a StorageClass.

1. Ensure that all nodes in your cluster have the topology key set. Here we
   will set a custom node zone label.

    > 💡 If PVC label `storageos.com/topology-key` is not set, the node label
    > `topology.kubernetes.io/zone` is used by default.

    ```
    kubectl label node worker-1 custom-region=1 
    kubectl label node worker-2 custom-region=2
    kubectl label node worker-3 custom-region=3
    ```

1. Create a new PVC with no replicas.

    ```
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-tap
      labels:
        storageos.com/topology-aware: "true"        # <---- Enable TAP
        storageos.com/topology-key: custom-region # <---- TAP failure domain node label key
        storageos.com/failure-mode: soft
    spec:
      storageClassName: storageos
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    ```

1. Increase the number of replicas to match the number of zones. We will do
   this via the CLI for convenience.

    ```
    kubectl label pvc pvc-tap storageos.com/replicas=3
    ```

    > 💡 To place 3 replicas, the cluster needs at least 4 nodes (1 primary + 3
    > replicas).

## Result

You have enabled TAP per volume. You can check the location of your master and
replicas with the CLI. Note, that the replicas have been evenly distributed
between the zones we just set.

Get the volume name:

```
kubectl get pvc pvc-tap-test-owide
```

You will get the following:

```
pvc-tap-test   Bound    pvc-49404512-7905-42a3-be94-a56854796bdd /docs.
```

Now, you can look up that volume with the CLI:

```
storageos describe volume pvc-49404512-7905-42a3-be94-a56854796bdd
```

```
    /docs.
    Master:
      ID                3ed41e62-a28b-4a93-bbf2-504de31ee848
      Node              worker1 (53927506-0ebd-4470-b910-6611caecad18)
      Health            online

    Replicas:
      ID                99e9e983-234b-48e6-9da7-a7f323076bfe
      Node              worker3 (a535a95f-ef2d-4e47-be1e-1685615a8f21)
      Health            ready
      Promotable        true

      ID                4b4c632d-f991-4120-92ac-f5a99e670b53
      Node              worker2 (47d36fa7-dc31-4469-aca2-ce70fbeac449)
      Health            ready
      Promotable        true
```
