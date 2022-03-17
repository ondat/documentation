
## Get Started Guide - Deploying Percona's Distribution for PostgreSQL Operator on a SUSE Rancher Kubernetes Engine (RKE) with Ondat


### Overview

- In this get started guide, we will be deploying [Percona's Distribution for PostgreSQL Operator](https://www.percona.com/doc/kubernetes-operator-for-postgresql/index.html) on a SUSE Rancher Kubernetes Engine (RKE) with Ondat. 
- We will leverage [Rancher's DigitalOcean Quick Start Guide](https://rancher.com/docs/rancher/v2.6/en/quick-start-guide/deployment/digital-ocean-qs/), which uses Terraform and has been modified to deploy a single-node [K3s](https://k3s.io/) for [Rancher Server](https://rancher.com/docs/rancher/v2.6/en/quick-start-guide/deployment/) and a highly available [Rancher Kubernetes Engine](https://rancher.com/docs/rke/latest/en/installation/) cluster that has 3 master nodes and 5 worker nodes.
- Once the 2 clusters are up and running, the next step will be to deploy and configure [Ondat](https://www.ondat.io/) - a software-defined, cloud native storage platform for Kubernetes.
- Percona's Distribution for PostgreSQL Operator will then be deployed as our Database as a Service operator in the RKE workload cluster and, we will deploy a stateful database workload as an example.
- We will then provide a demonstration of Ondat's features, such as [fast replication](https://docs.ondat.io/docs/concepts/replication/) and [encryption at rest](https://www.ondat.io/blog/storageos-kubernetes-encryption-at-rest) for the volumes of the stateful database workload example deployed.

### Prerequisites

> **Important Note**
> - Provisioning and deploying application workloads in DigitalOcean will incur charges against your billing account as a result. 
> - **Users must be aware that they will be responsible for any of the infrastructure costs incurred by creating and using DigitalOcean's cloud resources.**
	> 	- For users new to DigitalOcean, they can sign up for a [free trial offer worth $100 of credit for 60 days](https://try.digitalocean.com/freetrialoffer/) to get started and test.
> - **Ensure that you destroy/tear down any of the resources that you have provisioned after you have completed this guide.**

- You have verified and checked  the following items listed below have been completed first;
	- **DigitalOcean**
		- Have a [DigitalOcean Account](https://www.digitalocean.com/) to use the cloud resources.
		- Have a [DigitalOcean Personal Access Token](https://docs.digitalocean.com/reference/api/create-personal-access-token/) generated for interacting with cloud resources through DigitalOcean's API.
	- **HashiCorp**
		- Have installed and configured [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) on your local machine, and it is available in your `$PATH`.
	- **Git**
		- Have installed and configured [git](https://git-scm.com/) on your local machine, and it is available in your `$PATH`. 
	- **Kubernetes** 
		- Have installed and configured [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) on your local machine, and it is available in your `$PATH`. 
	- **Ondat**
		- Have installed and configured [kubectl-storageos](https://docs.ondat.io/docs/reference/kubectl-plugin/) on your local machine, and it is available in your `$PATH`. 

### Procedure

#### Step 1 - Provision A Rancher Server & Rancher Kubernetes Engine Workload Cluster on DigitalOcean.

- Run the following commands to clone the repository to your local machine and navigate into the DigitalOcean directory, which contains the Terraform configuration files that will be used to provision the following resources below;
	- Single-node K3s cluster for Rancher Server, and a;
	- Highly available Rancher Kubernetes Engine cluster that has 3 master nodes and 5 worker nodes.

```bash
# Clone the repository.
git clone git@github.com:hubvu/rke-ondat-digitalocean.git

# Navigate into the `do/` directory.
cd rke-ondat-digitalocean/do/
```

- Rename the  `terraform.tfvars.example`  file to  `terraform.tfvars`;

```bash
# Rename `terraform.tfvars.example`.
mv terraform.tfvars.example terraform.tfvars
```

- Customise the following environment variables in the `terraform.tfvars` file using your preferred text editor and enter the requested values. You can create your own administrative password for your Rancher Server;

```bash
# DigitalOcean API token used to create infrastructure.
do_token = ""

# Admin password to use for Rancher server bootstrap.
rancher_server_admin_password = ""
```

- Save the newly defined variables and then run the following command to initialise the working directory containing the configuration files.

```bash
# Initialise the working directory containing the configuration files.
terraform init
```

- Validate your Terraform configuration files and plan an execution plan.

```bash
# Validate the configuration files in the working directory.
terraform validate

# Create an execution plan first.
terraform plan
```

- Run the following command to provision the resources defined in the Terraform configuration files.
	> Provisioning infrastructure may take some time to complete, please be patient and wait for provisioning  to successfully complete before moving onto the next step.

```bash
# Execute the actions proposed in a plan created earlier.
terraform apply --auto-approve
```
- Once provisioning is complete, you will see an output similar to the following:

```bash
Apply complete! Resources: 21 added, 0 changed, 0 destroyed.

Outputs:

rancher_server_node_ip = "xxx.xxx.xxx.xxx"
rancher_server_url = "https://rancher.xxx.xxx.xxx.xxx.sslip.io"
rke_master_node_1_ip = "xxx.xxx.xxx.xxx"
rke_master_node_2_ip = "xxx.xxx.xxx.xxx"
rke_master_node_3_ip = "xxx.xxx.xxx.xxx"
rke_worker_node_1_ip = "xxx.xxx.xxx.xxx"
rke_worker_node_2_ip = "xxx.xxx.xxx.xxx"
rke_worker_node_3_ip = "xxx.xxx.xxx.xxx"
rke_worker_node_4_ip = "xxx.xxx.xxx.xxx"
rke_worker_node_5_ip = "xxx.xxx.xxx.xxx"
```

- To access the Rancher Server WebUI and - copy and paste the `rancher_server_url` from the output into your browser (Firefox) and log in when prompted.
	- The default username is `admin` and the password is the value one you defined as your `rancher_server_admin_password` in the `terraform.tfvars` file.
- To access the RKE workload cluster through `kubectl`, run the following commands to copy the generated `kube_config_workload.yaml` file to `~/.kube/config` and inspect the nodes and pods with `kubectl`.

```bash
# Set the generated kubeconfig file for the workload cluster.
cp kube_config_workload.yaml ~/.kube/config

# Inspect the nodes and pods.
kubectl get nodes
kubectl get pods --all-namespaces
```

> **Note** 
> - It can take some time (~15 minutes) for the RKE workload cluster `quickstart-do-custom` to register each node and report back to the Rancher Server, please be patient until all the nodes are registered and are in a ready state. 
>   - You can check the status of the node registrations through the Rancher Server WebUI by reviewing the "Cluster Management" tab or executing `kubectl get nodes` until all the 8 nodes are in a `Ready` status.

#### Step 2 - Deploy & Configure Ondat

- By default, a newly provisioned RKE cluster does not have any CSI driver deployed. Run the following commands against the cluster to deploy a [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) to provide local storage for Ondat's `etcd` deployment.

```bash
# Install the local path provisioner.
kubectl apply --filename="https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml"

# Inspect the status of the pod and storageclass.
kubectl get pod --namespace=local-path-storage
kubectl get storageclass
```
- Run the following `kubectl-storageos` plugin command to conduct preflight checks against the RKE workload cluster to validate that Ondat prerequisites have been met before attempting an installation.

```bash
# Conduct preflight checks.
kubectl storageos preflight
```

- Define and export the  `STORAGEOS_USERNAME`  and  `STORAGEOS_PASSWORD`  environment variables that will be used as your credentials to access and manage your Ondat instance.

```bash
export STORAGEOS_USERNAME="admin"
export STORAGEOS_PASSWORD="password"
```

- Run the following `kubectl-storageos` plugin command to install Ondat.

```bash
# Install Ondat.
kubectl storageos install \
  --include-etcd \
  --etcd-tls-enabled \
  --etcd-storage-class="local-path" \
  --admin-username="$STORAGEOS_USERNAME" \
  --admin-password="$STORAGEOS_PASSWORD"
```

- The installation process may take a few minutes.
- Once the installation is complete, run the following  `kubectl `commands to inspect Ondat’s resources (the core components should all be in a  `RUNNING`  status).

```bash
# Inspect Ondat resources that have been created.
kubectl get all --namespace=storageos
kubectl get all --namespace=storageos-etcd
kubectl get storageclasses | grep "storageos"
```

- Now that you have Ondat running successfully, execute the following commands to create a customised Ondat  `StorageClass`  and set it as the default  `StorageClass`  for the cluster. Ondat leverages  [feature labels](https://docs.ondat.io/docs/reference/labels/)  to enable key capabilities such as;
    1.  [Fast Replication](https://docs.ondat.io/docs/concepts/replication/)
    2.  [Topology-Aware Placement (TAP)](https://docs.ondat.io/docs/operations/tap/)
    3.  [Encryption At Rest](https://docs.ondat.io/docs/operations/encryption/)

```bash
# Label the worker nodes to define custom regions for the TAP feature.
kubectl label node demo-worker-node-1 custom-region=1 
kubectl label node demo-worker-node-2 custom-region=2
kubectl label node demo-worker-node-3 custom-region=3
kubectl label node demo-worker-node-4 custom-region=1
kubectl label node demo-worker-node-5 custom-region=2

# Check that the worker nodes have been labeled successfully.
kubectl describe nodes | grep "custom-region"
```

```bash
# Create a customised Ondat StorageClass named `ondat-replication-encryption`.
cat <<EOF | kubectl create --filename -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ondat-replication-encryption
provisioner: csi.storageos.com
allowVolumeExpansion: true
parameters:
  csi.storage.k8s.io/fstype: ext4
  storageos.com/replicas: "2"
  storageos.com/encryption: "true"
  storageos.com/topology-aware: "true"
  storageos.com/topology-key: "custom-region"
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
EOF
```

```bash
# Mark the `ondat-replication-encryption` StorageClass as the default StorageClass for the cluster.
kubectl patch storageclass ondat-replication-encryption -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Inspect the StorageClass and ensure it's now the default.
kubectl get storageclasses | grep "ondat-replication-encryption"
```

#### Step 3 - Deploy Percona's Distribution for PostgreSQL Operator

- In this step, you will deploy the [PostgreSQL operator](https://github.com/percona/percona-postgresql-operator) that is developed and maintained by Percona. Run the following commands below to deploy the  operator.

```bash
# Create a namespace for the operator.
kubectl create namespace pgo

# Deploy the PostgreSQL operator.
kubectl --namespace=pgo apply --filename="https://raw.githubusercontent.com/percona/percona-postgresql-operator/main/deploy/operator.yaml"

# Inspect that the status of the pod is in a `RUNNING` state.
kubectl get pods --namespace=pgo
```

-  Once the operator is up and running, run the following command to create the database cluster itself from the custom resource provided in the `/percona-postgresql` directory located in the repository.

```bash
# Deploy the database cluster.
kubectl --namespace=pgo apply --filename=../percona-postgresql/cr.yaml --namespace=pgo

# Inspect that the resources have been successfully created in the `pgo` namespace.
kubectl get pods --namespace=pgo

# Check connectivity to the newly created cluster and exit once confirmed.
kubectl --namespace=pgo run -i --rm --tty pg-client --image=perconalab/percona-distribution-postgresql:13.2 --restart=Never -- bash -il
```

#### Step 4 - Exploring Ondat's Replication & Encryption Features

- In this step, we will explore Ondat's fast replication capability and encryption at rest for volumes in the cluster. 
- Before we explore some of Ondat's key features, we are going to deploy and run the [Ondat CLI utility as a deployment in the RKE workload cluster](https://docs.ondat.io/docs/reference/cli/#run-the-cli-as-a-deployment-in-your-cluster) so that you can interact and manage Ondat.
	- Run the following command to deploy the CLI into your cluster.

```bash
# Create the deployment for the Ondat CLI.
cat <<EOF | kubectl create --filename -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storageos-cli
  namespace: storageos
  labels:
    app: storageos
    run: cli
spec:
  replicas: 1
  selector:
    matchLabels:
      app: storageos-cli
      run: cli
  template:
    metadata:
      labels:
        app: storageos-cli
        run: cli
    spec:
      containers:
      - command:
        - /bin/sh
        - -c
        - "while true; do sleep 3600; done"
        env:
        - name: STORAGEOS_ENDPOINTS
          value: http://storageos:5705
        - name: STORAGEOS_USERNAME
          value: "admin"
        - name: STORAGEOS_PASSWORD
          value: "password"
        image: storageos/cli:v2.5.0
        name: cli
EOF
```

```bash
# Get the CLI pod name and take note of it for future use.
kubectl --namespace=storageos get pod -ocustom-columns=_:.metadata.name --no-headers -lapp=storageos-cli
```

- **Ondat's Fast Replication**
	- Upon deploying the PostgreSQL operator in *Step 3*, Ondat automatically created 2 replica volumes for each master volume created. You can review the volumes created by running the following commands below;

```bash
# Get the volumes in the `pgo` namespace.
kubectl --namespace=storageos exec storageos-cli-77748d9c84-vn5hz -- storageos get volumes --namespace=pgo

NAMESPACE  NAME                                      SIZE     LOCATION                     ATTACHED ON         REPLICAS  AGE
pgo        pvc-e334dec5-facf-4290-81ff-14ca7828820c  1.0 GiB  demo-worker-node-3 (online)  demo-worker-node-3  2/2       3 minutes ago
pgo        pvc-68181113-ab9c-41e1-a46f-5bde24c6b488  1.0 GiB  demo-worker-node-3 (online)  demo-worker-node-3  2/2       5 minutes ago
pgo        pvc-0a0255a3-35a3-412a-bfb7-a22799853188  1.0 GiB  demo-worker-node-3 (online)  demo-worker-node-3  2/2       3 minutes ago
pgo        pvc-cd06f51c-2354-410b-aee5-15f970315204  1.0 GiB  demo-worker-node-3 (online)  demo-worker-node-3  2/2       5 minutes ago

# Describe the volume `pvc-e334dec5-facf-4290-81ff-14ca7828820c` in the `pgo` namespace.
kubectl --namespace=storageos exec storageos-cli-77748d9c84-vn5hz -- storageos describe volume pvc-e334dec5-facf-4290-81ff-14ca7828820c --namespace=pgo
ID                  114b14b7-6983-4680-9753-7ddacc16f6c8
Name                pvc-e334dec5-facf-4290-81ff-14ca7828820c
Description
AttachedOn          demo-worker-node-3 (44f0ede3-cd3b-4062-9c53-3843c7dba68a)
Attachment Type     host
NFS
  Service Endpoint
  Exports:
Namespace           pgo (f4cb1870-a1b7-4559-a2fc-6d94018033c1)
Labels              csi.storage.k8s.io/pv/name=pvc-e334dec5-facf-4290-81ff-14ca7828820c,
                    csi.storage.k8s.io/pvc/name=cluster1-repl1,
                    csi.storage.k8s.io/pvc/namespace=pgo,
                    pg-cluster=cluster1,
                    storageos.com/encryption=true,
                    storageos.com/nocompress=true,
                    storageos.com/replicas=2,
                    storageos.com/topology-aware=true,
                    storageos.com/topology-key=custom-region,
                    vendor=crunchydata
Filesystem          ext4
Size                1.0 GiB (1073741824 bytes)
Version             Mw
Created at          2022-02-21T13:02:06Z (4 minutes ago)
Updated at          2022-02-21T13:02:13Z (4 minutes ago)

Master:
  ID                a213f367-95ce-48b6-9cae-ad9867588473
  Node              demo-worker-node-3 (44f0ede3-cd3b-4062-9c53-3843c7dba68a)
  Health            online
  Topology Domain   3

Replicas:
  ID                8398776a-48fe-4bab-8aca-78fbde36803f
  Node              demo-worker-node-4 (8a56bb01-5992-48f1-b6d7-c764b5ab3f09)
  Health            ready
  Promotable        true
  Topology Domain   1

  ID                18a916ff-4534-4f9f-956b-72dd28ebd698
  Node              demo-worker-node-2 (a3ce438c-7fb5-4e89-b757-8115516c1a4a)
  Health            ready
  Promotable        true
  Topology Domain   2
```

* Each volume replica is deployed on a different node to ensure data protection and high availability in the event of a node experiences a transient failure. 
* As a demonstration, to show how quickly Ondat can fail over to a replica volume on a different node in the event of a node failure - we are going to delete the node where the master volume currently resides.
	* As shown in the `storageos describe volume pvc-e334dec5-facf-4290-81ff-14ca7828820c --namespace=pgo` command earlier, a master volume currently resides on `demo-worker-node-3` node and the related 2 replica volumes reside on `demo-worker-node-4` and `demo-worker-node-2` respectively. 
	* When `demo-worker-node-3` goes offline, Ondat will automatically detect that the master volume doesn't exist any more and elect one of the 2 replica volumes to become a master and create a new replica to on a different node to keep the defined replica volume count specified in the `ondat-replication-encryption` StorageClass created.

```bash
# To create a failure senario - delete the node with a master volume.
kubectl delete node/demo-worker-node-3

# Check that the node has been deleted.
kubectl get nodes

NAME                 STATUS   ROLES               AGE   VERSION
demo-master-node-1   Ready    controlplane,etcd   86m   v1.20.6
demo-master-node-2   Ready    controlplane,etcd   87m   v1.20.6
demo-master-node-3   Ready    controlplane,etcd   93m   v1.20.6
demo-worker-node-1   Ready    worker              85m   v1.20.6
demo-worker-node-2   Ready    worker              85m   v1.20.6
demo-worker-node-4   Ready    worker              85m   v1.20.6
demo-worker-node-5   Ready    worker              91m   v1.20.6

# Wait for a moment as Ondat elects a new master, creates a new 
# replica and then review the volumes in the `pgo` namespace again.
kubectl --namespace=storageos exec storageos-cli-77748d9c84-vn5hz -- storageos get volumes --namespace=pgo
NAMESPACE  NAME                                      SIZE     LOCATION                     ATTACHED ON  REPLICAS  AGE
pgo        pvc-e334dec5-facf-4290-81ff-14ca7828820c  1.0 GiB  demo-worker-node-2 (online)               2/2       12 minutes ago
pgo        pvc-68181113-ab9c-41e1-a46f-5bde24c6b488  1.0 GiB  demo-worker-node-1 (online)               2/2       15 minutes ago
pgo        pvc-0a0255a3-35a3-412a-bfb7-a22799853188  1.0 GiB  demo-worker-node-2 (online)               2/2       12 minutes ago
pgo        pvc-cd06f51c-2354-410b-aee5-15f970315204  1.0 GiB  demo-worker-node-2 (online)               2/2       15 minutes ago

# Describe the volume `pvc-e334dec5-facf-4290-81ff-14ca7828820c` in the `pgo` namespace again.
kubectl --namespace=storageos exec storageos-cli-77748d9c84-vn5hz -- storageos describe volume pvc-e334dec5-facf-4290-81ff-14ca7828820c --namespace=pgo
ID                  114b14b7-6983-4680-9753-7ddacc16f6c8
Name                pvc-e334dec5-facf-4290-81ff-14ca7828820c
Description
AttachedOn          demo-worker-node-4 (8a56bb01-5992-48f1-b6d7-c764b5ab3f09)
Attachment Type     host
NFS
  Service Endpoint
  Exports:
Namespace           pgo (f4cb1870-a1b7-4559-a2fc-6d94018033c1)
Labels              csi.storage.k8s.io/pv/name=pvc-e334dec5-facf-4290-81ff-14ca7828820c,
                    csi.storage.k8s.io/pvc/name=cluster1-repl1,
                    csi.storage.k8s.io/pvc/namespace=pgo,
                    pg-cluster=cluster1,
                    storageos.com/encryption=true,
                    storageos.com/nocompress=true,
                    storageos.com/replicas=2,
                    storageos.com/topology-aware=true,
                    storageos.com/topology-key=custom-region,
                    vendor=crunchydata
Filesystem          ext4
Size                1.0 GiB (1073741824 bytes)
Version             OQ
Created at          2022-02-21T13:02:06Z (21 minutes ago)
Updated at          2022-02-21T13:19:06Z (4 minutes ago)

Master:
  ID                18a916ff-4534-4f9f-956b-72dd28ebd698
  Node              demo-worker-node-2 (a3ce438c-7fb5-4e89-b757-8115516c1a4a)
  Health            online
  Topology Domain   2

Replicas:
  ID                8398776a-48fe-4bab-8aca-78fbde36803f
  Node              demo-worker-node-4 (8a56bb01-5992-48f1-b6d7-c764b5ab3f09)
  Health            ready
  Promotable        true
  Topology Domain   1

  ID                315514e6-3b5f-4926-bb51-d4b2e4cf0bb3
  Node              demo-worker-node-1 (54214d6e-15fa-4516-b657-dc1864c78358)
  Health            ready
  Promotable        true
  Topology Domain   1
```
- You can see that Ondat elected the replica volume on node `demo-worker-node-2`  to become the master volume since `demo-worker-node-3` no longer exist, and a new replica volume was created on node `demo-worker-node-1` to ensure that the replica volume count defined is consistent.

- **Ondat's Encryption At Rest**
	- Alongside supporting encryption of data in transit out-of-the-box through [Mutual TLS (mTLS) authentication](https://en.wikipedia.org/wiki/Mutual_authentication), Ondat provides the capability of being able to [encrypt data at rest](https://www.ondat.io/blog/storageos-kubernetes-encryption-at-rest) for volumes.
	- Encryption at rest can be enabled by simply adding a [feature label](https://docs.ondat.io/docs/reference/labels/) called `storageos.com/encryption=true` to your customised Ondat `StorageClass` parameters or `PersistentVolumeClaim` manifest for your application. 
		> - You may have noticed that the Ondat StorageClass created earlier already has this enabled alongside the replication feature label - thus, all the PostgreSQL operator volumes created under this StorageClass are encrypted at rest by default.

- To review how Ondat generates and handles encryption keys, run the following `kubectl`commands below;

```yaml
# Get a list of the PersistentVolumeClaims created in the `pgo` namespace.
kubectl get pvc --namespace=pgo

NAME                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                   AGE
cluster1             Bound    pvc-cd06f51c-2354-410b-aee5-15f970315204   1Gi        RWO            ondat-replication-encryption   30m
cluster1-pgbr-repo   Bound    pvc-68181113-ab9c-41e1-a46f-5bde24c6b488   1Gi        RWO            ondat-replication-encryption   30m
cluster1-repl1       Bound    pvc-e334dec5-facf-4290-81ff-14ca7828820c   1Gi        RWO            ondat-replication-encryption   28m
cluster1-repl2       Bound    pvc-0a0255a3-35a3-412a-bfb7-a22799853188   1Gi        RWO            ondat-replication-encryption   28m

# Describe the PersistentVolumeClaim of `cluster1-repl1` in the `pgo` namespace.
Name:          cluster1-repl1
Namespace:     pgo
StorageClass:  ondat-replication-encryption
Status:        Bound
Volume:        pvc-e334dec5-facf-4290-81ff-14ca7828820c
Labels:        pg-cluster=cluster1
               vendor=crunchydata
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               storageos.com/encryption-secret-name: storageos-volume-key-a551eeb4-af97-44b9-9f95-31bf25d06c76
               storageos.com/encryption-secret-namespace: pgo
               storageos.com/storageclass: c36edc44-3956-4101-8dfe-0e763411a4b3
               volume.beta.kubernetes.io/storage-provisioner: csi.storageos.com
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Used By:       cluster1-repl1-55d5b89b76-9wpkt
Events:
  Type    Reason                 Age   From                                                                                          Message
  ----    ------                 ----  ----                                                                                          -------
  Normal  Provisioning           30m   csi.storageos.com_storageos-csi-helper-65db657d7c-bn2zk_6d3ecaa5-7477-4e08-8713-a12baf49aa69  External provisioner is provisioning volume for claim "pgo/cluster1-repl1"
  Normal  ExternalProvisioning   30m   persistentvolume-controller                                                                   waiting for a volume to be created, either by external provisioner "csi.storageos.com" or manually created by system administrator
  Normal  ProvisioningSucceeded  30m   csi.storageos.com_storageos-csi-helper-65db657d7c-bn2zk_6d3ecaa5-7477-4e08-8713-a12baf49aa69  Successfully provisioned volume pvc-e334dec5-facf-4290-81ff-14ca7828820c
```

- In the output above, the `cluster1-repl1` PVC has the following Kubernetes annotations that are added to the PVC by an admission controller to map the PVC back to the secret.
```yaml
storageos.com/encryption-secret-name: storageos-volume-key-a551eeb4-af97-44b9-9f95-31bf25d06c76
storageos.com/encryption-secret-namespace: pgo
```
- When a PVC is created, Ondat will automatically generate 2 encryption keys and store them as Kubernetes Secrets in the same namespace where the PVC resides.

```bash
# Get a list of the Ondat secret keys created in the `pgo` namespace.
kubectl get secrets --namespace=pgo | grep "storageos"

storageos-namespace-key                                     Opaque                                1      35m
storageos-volume-key-210f2a72-c9d5-4c82-b990-77200fc4eada   Opaque                                4      32m
storageos-volume-key-3bd9768b-2beb-41c4-9f26-ea3fc66b294f   Opaque                                4      35m
storageos-volume-key-a551eeb4-af97-44b9-9f95-31bf25d06c76   Opaque                                4      32m
storageos-volume-key-c69c2deb-932c-4ded-be18-121cca0b0a42   Opaque                                4      35m

# Describe the `storageos-namespace-key` secret key.
kubectl describe secret storageos-namespace-key --namespace=pgo

Name:         storageos-namespace-key
Namespace:    pgo
Labels:       app.kubernetes.io/component=storageos-api-manager
              app.kubernetes.io/managed-by=storageos-operator
              app.kubernetes.io/name=storageos
              app.kubernetes.io/part-of=storageos
Annotations:  <none>

Type:  Opaque

Data
====
key:  32 bytes

# Describe the `storageos-volume-key-a551eeb4-af97-44b9-9f95-31bf25d06c76` secret key.
kubectl describe secret storageos-volume-key-a551eeb4-af97-44b9-9f95-31bf25d06c76 --namespace=pgo

Name:         storageos-volume-key-a551eeb4-af97-44b9-9f95-31bf25d06c76
Namespace:    pgo
Labels:       app.kubernetes.io/component=storageos-api-manager
              app.kubernetes.io/managed-by=storageos-operator
              app.kubernetes.io/name=storageos
              app.kubernetes.io/part-of=storageos
              storageos.com/pvc=cluster1-repl1
Annotations:  <none>

Type:  Opaque

Data
====
iv:    32 bytes
key:   64 bytes
vuk:   80 bytes
hmac:  32 bytes
```

- **Namespace Encryption Key**
	- For every namespace where PVCs will be provisioned, if it does not already exist, a unique namespace encryption key called `storageos-namespace-key` is generated and only 1 namespace key exists per namespace.
- **Volume Encryption Key**
	- Every volume provisioned in the namespace will have a unique volume encryption key associated with it, for example `storageos-volume-key-a551eeb4-af97-44b9-9f95-31bf25d06c76`. 
	- You can determine which volume is associated with a volume encryption key by reviewing the label on the Kubernetes Secret, for example `storageos.com/pvc=cluster1-repl1`.

```yaml
Name:         storageos-volume-key-a551eeb4-af97-44b9-9f95-31bf25d06c76
Namespace:    pgo
Labels:       app.kubernetes.io/component=storageos-api-manager
              app.kubernetes.io/managed-by=storageos-operator
              app.kubernetes.io/name=storageos
              app.kubernetes.io/part-of=storageos
              storageos.com/pvc=cluster1-repl1
```

- **Understanding How Encrypted Volumes Work**
	- An encrypted volume attached to a node for use by a pod will need the associated volume encryption key to be available. Ondat's daemonset ServiceAccount will read the secret key and pass it onto Ondat's control plane.
		- If a volume encryption key is missing/corrupt, then the encrypted volume will not be able to attach.
	- The volume encryption key is stored in memory by Ondat and only on the node that volume is attached to, thus encryption and decryption is only performed when data is being consumed, rather than where it is being stored. 
	- As the encryption keys are stored using the native [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) construct, you can integrate with supported Kubernetes [Key Management Service (KMS) providers](https://kubernetes.io/docs/tasks/administer-cluster/kms-provider/) such as [HashiCorp Vault](https://www.vaultproject.io/) to manage your secrets.
- **Attempt To Access Encrypted Data On A Node**
	- To verify that encryption of data at rest is working as expected, run the following commands below to attempt accessing the `cluster1-repl1`  deployment data that is stored as blob files on a node under the `/var/lib/storageos/data/` directory;

```bash
# Get the node location where `cluster1-repl1` pod is running.
kubectl get pods --namespace=pgo --output=wide | grep "cluster1-repl1"

cluster1-repl1-55d5b89b76-9wpkt                  1/1     Running     0          26m   10.42.7.8    demo-worker-node-4   <none>           <none>

# Use `kubectl debug` to temporarily run a 
# privileged container on a node `demo-worker-node-4`.
kubectl debug node/demo-worker-node-4 -it --image=ubuntu:latest

# Through the privileged container, update the repository 
# index and install `binutils` to access the `strings` utility.
apt update && apt install --yes binutils

# Navigate to where data is being stored as blob files on the node and list the files.
cd /host/var/lib/storageos/data/dev1/

ls -lah

total 1.3G
drwxr-xr-x 2 root root 4.0K Feb 21 13:13 .
drwxr-xr-x 5 root root 4.0K Feb 21 13:13 ..
-rw------- 1 root root 118M Feb 21 13:34 vol.143597.0.blob
-rw------- 1 root root 118M Feb 21 13:34 vol.143597.1.blob
-rw------- 1 root root  31M Feb 21 13:25 vol.229667.0.blob
-rw------- 1 root root  31M Feb 21 13:25 vol.229667.1.blob
-rw------- 1 root root 122M Feb 21 13:35 vol.251685.0.blob
-rw------- 1 root root 122M Feb 21 13:34 vol.251685.1.blob

# Use the `strings` utility to attempt to read the data in the blob files.
# The output of the command will return multiple strings of random, unreadable characters.
strings vol.* | head -20
edAS
I~6R
utjC
2*??Q
`\!#,b
X}pUl
6-au
N3V#
T6Nr*o
 Nf.
moC2P
&t	(O!m
YqWO
(4*S6
I)TxF
_ohb
dcY}
*9FM
l"	@
]D7'l

# Exit from the privileged container and return to your local shell.
exit
```

### Teardown Provisioned Resources

> Important

- Once you are finished testing out SUSE Rancher RKE, Ondat and Percona's Distribution for PostgreSQL Operator ensure that you remove the workloads deployed on the cluster, uninstall Ondat and teardown the cluster you provisioned to prevent incurring an unexpected cloud infrastructure bill.

```bash
# Delete the database cluster. 
kubectl --namespace=pgo delete --filename=../percona-postgresql/cr.yaml --namespace=pgo

# Delete the PostgreSQL operator. 
kubectl --namespace=pgo delete --filename="https://raw.githubusercontent.com/percona/percona-postgresql-operator/main/deploy/operator.yaml"

# Delete the `ngo` namespace. 
kubectl delete namespace pgo 

# Remove Ondat from the cluster.
kubectl storageos uninstall --include-etcd

# Delete the local path provisioner.
kubectl delete --filename="https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml"

# Destroy the environment created by Terraform
# to prevent incurring unexpected infrastructure 
# costs from the cloud provider resources used.
terraform destroy -auto-approve
```





-------

## Overview

Ondat makes it possible for cluster administrators to design and implement different cluster topologies, depending on types of workloads, use cases, priorities and needs. The topology approaches recommended below are idealised representations of possible Ondat clusters and can be mixed, modified and changed at execution time.

Ondat performs file Input/Output (I/O) operations over the network, which is how the platform ensures that data is always available throughout your cluster. This also affords cluster administrators certain possibilities of organising their clusters in ways explained below.

### Hyper-converged Cluster Topology

![Hyper-converged Cluster Topology](/images/docs/concepts/hyperconverged.png)

 - The [*hyper-converged*](https://en.wikipedia.org/wiki/Hyper-converged_infrastructure) cluster topology model leverages the available block storage attached to all the worker nodes in a Kubernetes cluster, creating a single storage pool that stores and present data for stateful workloads deployed and running.
	 - This cluster topology gives the best flexibility to Ondat and Kubernetes schedulers, and provides maximum choice for optimal pod placement when pods are being assigned to nodes in a cluster.
 - No matter how or where workloads are deployed on worker nodes, Ondat will ensure that the data from workloads is stored, persistent and always accessible. 
 - New Ondat deployments will place workloads locally where possible using this hyper-converged cluster topology out of the box.

### Centralised Cluster Topology

![Centralised Cluster Topology](/images/docs/concepts/centralised.png)

- The *centralised* cluster topology model leverages the available block storage attached to only a *subset* of worker nodes (creating a dedicated, storage-optimised [node pool](https://cloud.google.com/kubernetes-engine/docs/concepts/node-pools)) in a Kubernetes cluster, whilst the rest of the worker nodes are dedicated to running general and compute-intensive workloads, 
	- Deployed workloads in centralised cluster that require data persistency will access a dedicated storage pool that is located on the declared subset of worker nodes. 
- This cluster topology can be beneficial if, for example, cluster administers want to take advantage and effectively utilise high performance-optimised hardware components of a particular set of worker nodes for different types of workloads being deployed.
- The cluster topology can also aid in avoiding downtime issues that can arise from unaccounted resource/capacity planning and allocation for workloads, since storage-optimised nodes and compute-optimised workloads are compartmentalised.
- In addition, another suitable use case for this topology is for elastic worker node fleets with burst-able workloads. A fleet can be quickly expanded with new worker nodes for compute-intensive workloads on demand, whilst maintaining a centralised data storage pool that is not impacted by rapid auto cluster scaling.
- To configure this cluster topology for a new Ondat deployment, cluster administrators would need to apply an Ondat node label called `storageos.com/computeonly` to nodes, which would inform Ondat that it *should not* use the nodes to join a storage pool.
	- Review the [Feature Labels](https://docs.ondat.io/docs/reference/labels/) reference page for more information on how to enable Ondat features correctly.



------


---
title: "Azure Kubernetes Service (AKS)"
linkTitle: "Azure Kubernetes Service (AKS)"
weight: 1
---

## Overview

This guide will demonstrate how to install Ondat onto a [Microsoft Azure Kubernetes Service (AKS)](https://azure.microsoft.com/en-gb/services/kubernetes-service/) cluster using the [Ondat kubectl plugin](/docs/reference/kubectl-plugin/).

## Prerequisites

> ⚠️ Make sure you have met the minimum resource requirements for Ondat to successfully run. Review the main [Ondat prerequisites](/docs/prerequisites/) page for more information.

> ⚠️ Make sure the following CLI utilities are installed on your local machine and are available in your `$PATH`:

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
* [kubectl-storageos](/docs/reference/kubectl-plugin/)

> ⚠️ Make sure to add an [Ondat licence](/docs/operations/licensing/) after installing.

> ⚠️ Make sure you have a running AKS cluster with a minimum of 3 worker nodes and the sufficient [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) permissions to deploy and manage applications in the cluster.

> ⚠️ Make sure your AKS cluster uses [Ubuntu](https://ubuntu.com/) as the default node operating system with an optimised kernel. Any Ubuntu-based node operating system with a kernel version greater than `4.15.0-1029-azure` is compatible with Ondat.

## Procedure

### Step 1 - Conducting Preflight Checks

- Run the following command to conduct preflight checks against the AKS cluster to validate that Ondat prerequisites have been met before attempting an installation.

```bash
kubectl storageos preflight
```

### Step 2 - Installing Ondat

1. Define and export the `STORAGEOS_USERNAME` and `STORAGEOS_PASSWORD` environment variables that will be used to manage your Ondat instance.

```bash
export STORAGEOS_USERNAME="storageos"
export STORAGEOS_PASSWORD="storageos"
```

2. Run the following  `kubectl-storageos` plugin command to install Ondat.

```bash
kubectl storageos install \
  --include-etcd \
  --etcd-tls-enabled \
  --admin-username="$STORAGEOS_USERNAME" \
  --admin-password="$STORAGEOS_PASSWORD"
```

- The installation process may take a few minutes.

### Step 3 - Verifying Ondat Installation

- Run the following `kubectl` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status)

```bash
kubectl get all --namespace=storageos
kubectl get all --namespace=storageos-etcd
kubectl get storageclasses | grep "storageos"
```

### Step 4 - Applying a Licence to the Cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our personal licence is free, and supports up to 1 TiB of provisioned storage.

To obtain a licence, follow the instructions on our [licensing operations](/docs/operations/licensing) page.
