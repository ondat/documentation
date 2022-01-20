---
title: "Deleting Ondat Objects"
linkTitle: Deleting Ondat Objects
---

When a Kubernetes object is deleted, Ondat controllers automatically sync
this deletion to Ondat. For example, when a Kubernets node is deleted, this
will automatically be mirrored in Ondat, likewise with Namespaces.

1. Here is an Ondat node, running on Kubernetes node worker1. An Ondat
   node is any machine that is running the Ondat daemonset pod. The node is
   visible below in kubectl.
    ```
    $ kubectl describe -n storageos pod storageos-daemonset-6q4g8
    Name:                 storageos-daemonset-6q4g8
    Namespace:            storageos
    Priority:             2000001000
    Priority Class Name:  system-node-critical
    Node:                 worker1/192.168.152.238
    Start Time:           Thu, 06 May 2021 15:53:34 +0100
    Labels:               app=storageos
                          app.kubernetes.io/component=storageos-daemonset
                          app.kubernetes.io/instance=example-ondat
                          app.kubernetes.io/managed-by=storageos-operator
                          app.kubernetes.io/name=storageos
                          app.kubernetes.io/part-of=storageos
                          controller-revision-hash=f5dcf577d
                          kind=daemonset
                          pod-template-generation=1
                          storageos_cr=example-ondat
    Annotations:          kubectl.kubernetes.io/default-logs-container: storageos
    Status:               Running
    IP:                   192.168.152.238
    ...
    ```
    The nodes in your cluster can be seen with `storageos get nodes`.
    ```
    $ storageos get nodes
    NAME          HEALTH  AGE        LABELS                              
    worker1       online  1 day ago  beta.kubernetes.io/arch=amd64,      
                                     beta.kubernetes.io/os=linux,        
                                     cattle.io/creator=norman,           
                                     kubernetes.io/arch=amd64,           
                                     kubernetes.io/hostname=worker1,
                                     kubernetes.io/os=linux,             
                                     node-role.kubernetes.io/worker=true
                                     storageos.com/computeonly=true 
    worker2       online  1 day ago  beta.kubernetes.io/arch=amd64,      
                                     beta.kubernetes.io/os=linux,        
                                     cattle.io/creator=norman,           
                                     kubernetes.io/arch=amd64,           
                                     kubernetes.io/hostname=worker2,
                                     kubernetes.io/os=linux,             
                                     node-role.kubernetes.io/worker=true 
    worker3       online  1 day ago  beta.kubernetes.io/arch=amd64,      
                                     beta.kubernetes.io/os=linux,        
                                     cattle.io/creator=norman,           
                                     kubernetes.io/arch=amd64,           
                                     kubernetes.io/hostname=worker3,
                                     kubernetes.io/os=linux,             
                                     node-role.kubernetes.io/worker=true
    ...
    ```

2.  Delete the node.
    ```
    $ kubectl delete node worker1
    ```

3. Verify that the node has been deleted with `kubectl get nodes` or
   `storageos get nodes`. The node has now disappeared from Ondat.
    ```
    $ storageos get nodes
    NAME          HEALTH  AGE        LABELS                              
    worker2       online  1 day ago  beta.kubernetes.io/arch=amd64,      
                                     beta.kubernetes.io/os=linux,        
                                     cattle.io/creator=norman,           
                                     kubernetes.io/arch=amd64,           
                                     kubernetes.io/hostname=worker2,
                                     kubernetes.io/os=linux,             
                                     node-role.kubernetes.io/worker=true 
    worker3       online  1 day ago  beta.kubernetes.io/arch=amd64,      
                                     beta.kubernetes.io/os=linux,        
                                     cattle.io/creator=norman,           
                                     kubernetes.io/arch=amd64,           
                                     kubernetes.io/hostname=worker3,
                                     kubernetes.io/os=linux,             
                                     node-role.kubernetes.io/worker=true 
    ...
    ```
