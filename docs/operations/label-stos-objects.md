---
title: "Labeling Ondat Objects"
linkTitle: Labeling Ondat Objects
---

For more information regarding the Ondat Label Sync feature, see our
[Kubernetes Object Sync reference page.](/docs/reference/kubernetes-object-sync)

## Label Syncing
The Ondat API Manager handles cases where information from objects in your
Kubernetes Cluster needs to be synced to your Ondat cluster.

## Label Syncing on PVCs

The below guide shows how to apply a label to your PVCs, and how these labels
sync through to your Ondat Volumes. This operation is used often - for
example it is used here to add replicas to a Ondat Volume.

1. Create a PVC, following the instructions [here](/docs/operations/firstpvc). 
When you create a PVC, Ondat
automatically provisions an Ondat volume for it. An example PVC and
Ondat volume can be seen below. Note the labels `app=mysql` and `env=prod`
under `Labels`in the PVC description and the `VolumeAttributes`of the Ondat
Volume.

   ```  
   $ kubectl describe pvc/data-mysql-0
   Name:          data-mysql-0
   Namespace:     default
   StorageClass:  storageos
   Status:        Bound
   Volume:        pvc-2e6339f0-96f9-4098-a388-149fd0daa14f
   Labels:        app=mysql
                  env=prod
   Annotations:   pv.kubernetes.io/bind-completed: yes
                  pv.kubernetes.io/bound-by-controller: yes
                  storageos.com/storageclass: 572794ab-2d02-4fec-9aaf-43cd725f498e
                  volume.beta.kubernetes.io/storage-provisioner: csi.storageos.com
   ...  
   ```

   ```
   $ storageos describe volume pvc-2e6339f0-96f9-4098-a388-149fd0daa14f -oyaml
   id: 286fd3a6-c8f8-480a-b5e1-d16896db0c72
   name: pvc-2e6339f0-96f9-4098-a388-149fd0daa14f
   ...
   labels:
       app: mysql
       csi.storage.k8s.io/pv/name: pvc-2e6339f0-96f9-4098-a388-149fd0daa14f
       csi.storage.k8s.io/pvc/name: data-mysql-0
       csi.storage.k8s.io/pvc/namespace: default
       env: prod
       storageos.com/nocompress: "true"
       storageos.com/replicas: "0"
   ...
   ```
    
1. Now, apply a label to the PVC.
    
    ```
    $ kubectl label pvc data-mysql-0 storageos.com/replicas=3
    ```

2. By using the Ondat CLI, you can verify that the label applied has
   been synced through to our Ondat volume and the replicas are all
   present.
    ```
    $ storageos describe volume pvc-2e6339f0-96f9-4098-a388-149fd0daa14f -oyaml
    id: 286fd3a6-c8f8-480a-b5e1-d16896db0c72
    name: pvc-2e6339f0-96f9-4098-a388-149fd0daa14f
    description: ""
    attachedOn: 72b50fa0-d870-4d57-95fc-980cc41ab951
    attachedOnName: worker5
    attachmentType: host
    nfs:
        exports: []
        serviceendpoint: ""
    namespaceID: d4eb1a29-39e1-477f-b57c-1c264b797575
    namespaceName: default
    labels:
        app: mysql
        csi.storage.k8s.io/pv/name: pvc-2e6339f0-96f9-4098-a388-149fd0daa14f
        csi.storage.k8s.io/pvc/name: data-mysql-0
        csi.storage.k8s.io/pvc/namespace: default
        env: prod
        storageos.com/nocompress: "true"
        storageos.com/replicas: "3"
    filesystem: ext4
    sizeBytes: 5368709120
    master:
        id: 836d8bbc-d356-4ad1-89d2-b1da7f6a4e47
        nodeID: 72b50fa0-d870-4d57-95fc-980cc41ab951
        nodeName: worker5
        health: online
        promotable: true
    replicas:
      - id: 46d9ef46-7572-4b23-80c9-097b77c4f7a0
        nodeID: b812eb26-f59e-4867-824f-152acfa70968
        nodeName: worker4
        health: ready
        promotable: true
      - id: 7876164b-b2f0-4148-9688-6b154dfa073a
        nodeID: 52a98f1a-4d33-41e6-891a-6931052c4ba3
        nodeName: worker1
        health: ready
        promotable: true
      - id: 3987e698-68c9-4e8b-adee-16d0f424a106
        nodeID: d2b8ca25-4ffb-43ae-90cc-e1bc68be12ee
        nodeName: worker6
        health: ready
        promotable: true
    createdAt: 2021-05-06T14:57:58Z
    updatedAt: 2021-05-06T16:47:26Z
    version: Mzg
    ```
    
## Label Syncing on Nodes

Some Ondat functionality is set by labeling nodes - for example setting a
node to "compute-only" mode, as demonstrated here.

1. Note labels on the node that will be labeled and on the Ondat node corresponding to that
   Kubernetes node.
    ```
    $ kubectl describe node worker1 
    Name:               worker1
    Roles:              worker
    Labels:             beta.kubernetes.io/arch=amd64
                beta.kubernetes.io/os=linux
                cattle.io/creator=norman
                kubernetes.io/arch=amd64
                kubernetes.io/hostname=worker1
                kubernetes.io/os=linux
                node-role.kubernetes.io/worker=true
    Annotations:        csi.volume.kubernetes.io/nodeid: {"csi.storageos.com":"52a98f1a-4d33-41e6-891a-6931052c4ba3"}
                flannel.alpha.coreos.com/backend-data: {"VtepMAC":"06:7b:af:b9:a5:2b"}
                flannel.alpha.coreos.com/backend-type: vxlan
                flannel.alpha.coreos.com/kube-subnet-manager: true
                flannel.alpha.coreos.com/public-ip: 212.71.244.105
                node.alpha.kubernetes.io/ttl: 0
                projectcalico.org/IPv4IPIPTunnelAddr: 10.42.2.1
                rke.cattle.io/external-ip: 212.71.244.105
                rke.cattle.io/internal-ip: 192.168.152.238
                volumes.kubernetes.io/controller-managed-attach-detach: true
    CreationTimestamp:  Thu, 06 May 2021 13:28:30 +0100
    ...
    ```

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
    IPs:
      IP:           192.168.152.238
    ```

2. Now, apply the label to the node.
    ```
    $ kubectl label node worker1 storageos.com/computeonly=true
    ```

3. The label has synced to the node and it has been set to `compute-only`
   mode.
    ```
    $ storageos describe node worker1
    ID                                      52a98f1a-4d33-41e6-891a-6931052c4ba3    
    Name                                    worker1                                 
    Health                                  online                                  
    Addresses:                            
      Data Transfer address                 192.168.152.238:5703                    
      Gossip address                        192.168.152.238:5711                    
      Supervisor address                    192.168.152.238:5704                    
      Clustering address                    192.168.152.238:5710                    
    Labels                                  beta.kubernetes.io/arch=amd64,          
                        beta.kubernetes.io/os=linux,            
                        cattle.io/creator=norman,               
                        kubernetes.io/arch=amd64,               
                        kubernetes.io/hostname=worker1,         
                        kubernetes.io/os=linux,                 
                        node-role.kubernetes.io/worker=true,    
                        storageos.com/computeonly=true
    ```

