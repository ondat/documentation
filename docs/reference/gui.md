---
linkTitle: GUI
---

# GUI

Ondat provides a GUI for cluster and volume management.

The GUI is available at port 5705 on any of the nodes in the cluster. Initially
you can log in as the default administrator, with the username and password
from the `storageos-api` Secret. By default `storageos`, `storageos`.

> You can access the GUI by either port-forwarding with kubectl or using an
> Ingress rule. i.e `kubectl -n storageos port-forward svc/storageos 5705`.

![Logging in](/images/docs//gui-v2/login.png)

## Nodes

![Nodes](/images/docs/gui-v2/nodes.png)
![Node detail](/images/docs/gui-v2/node-detail.png)

## Volumes

You can create volumes, including replicated volumes, and view volume details:

![Viewing storage volumes](/images/docs/gui-v2/volumes.png)
![Viewing details of a volume](/images/docs/gui-v2/volume-detail.png)

## Licensing

![License](/images/docs/gui-v2/license.png)

## Cluster info

![Cluster](/images/docs/gui-v2/cluster.png)

## Namespaces

Volumes can be namespaced across different projects or teams, and you can switch namespace using the left hand panel:

![Viewing namespaces](/images/docs/gui-v2/namespaces.png)
