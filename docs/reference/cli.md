---
title: "Ondat Command Line Interface (CLI) Utility"
linkTitle: "Ondat Command Line Interface (CLI) Utility"
weight: 1
---

## Overview

- The Ondat CLI is a utility tool that is used to manage and configure Ondat resources and conduct Day-2 storage operations. The Ondat CLI is also useful for providing useful information on the state of an Ondat cluster and troubleshooting issues.
  - The project repository is open source and can be located on [GitHub](https://github.com/storageos/go-cli).

## Prerequisites

- Ensure that you have successfully [installed Ondat](/docs/install/) into your Kubernetes or Openshift cluster.

## How To Install The Ondat CLI

### Option 1 - Run The Ondat CLI As A Deployment (Recommended)

- Run the following command below against your Ondat cluster which will deploy the Ondat CLI using a [Kubernetes deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

```bash
# Create the deployment for the Ondat CLI.
cat <<EOF | kubectl create --filename -
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: storageos-cli
    app.kubernetes.io/component: storageos-cli
    app.kubernetes.io/part-of: storageos
    kind: storageos
  name: storageos-cli
  namespace: storageos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: storageos-cli
  template:
    metadata:
      labels:
        app: storageos-cli
    spec:
      containers:
      - command:
        - /bin/sh
        - -c
        - while true; do sleep 3600; done
        env:
        - name: STORAGEOS_USERNAME
          value: storageos
        - name: STORAGEOS_PASSWORD
          value: storageos
        - name: STORAGEOS_ENDPOINTS
          value: storageos:5705
        image: storageos/cli:v2.8.1
        imagePullPolicy: Always
        name: cli
        ports:
        - containerPort: 5705
        resources:
          limits:
            cpu: 100m
            memory: 128Mi
          requests:
            cpu: 50m
            memory: 32Mi
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
EOF
```

#### Execute Commands Through The Ondat CLI Deployment

- Once the Ondat CLI deployment resource has been successfully created, get the pod name and take note of it for later reference.

```bash
# Get the pod name of the Ondat CLI utility.
kubectl get pods --namespace storageos | grep "storageos-cli"

storageos-cli-75874cd77f-b5dgp                       1/1     Running   0              35m
```

- You can then use [`kubectl-exec`](https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/) to run Ondat CLI commands in the container as demonstrated below;

```bash
kubectl --namespace=storageos exec storageos-cli-75874cd77f-b5dgp -- storageos version
```

> 💡 Deploying the Ondat CLI as a deployment is the recommended method as the Ondat support bundle generation tool can automatically detect a deployment called `cli` and warn you if you do not have the CLI installed.

### Option 2 - Run The Ondat CLI On A Workstation

- To be able to interact and manage your Ondat cluster, ensure that you define and export the `STORAGEOS_USERNAME`, `STORAGEOS_PASSWORD` and `STORAGEOS_ENDPOINTS` environment variables that will be used to manage your Ondat cluster through the CLI.

```bash
export STORAGEOS_USERNAME="storageos"                    
export STORAGEOS_PASSWORD="storageos"
export STORAGEOS_ENDPOINTS="storageos.storageos.svc:5705"  # Enter the endpoint address of Ondat's REST API to access the cluster through the CLI.
                                                           # When using "kubectl port-forward" to access the cluster, change the endpoint to "localhost:5705".
```

- Once you have defined the environment variables above, install the Ondat CLI on one of the supported operating systems listed below;

#### Linux

```bash
curl --silent --show-error --location --output storageos \
  https://github.com/storageos/go-cli/releases/download/v2.8.1/storageos_linux_amd64 \
  && chmod +x storageos \
  && sudo mv storageos /usr/local/bin/ \
  && echo "CLI version installed:" \
  && storageos version
```

#### macOS (Darwin)

```bash
curl --silent --show-error --location --output storageos \
  https://github.com/storageos/go-cli/releases/download/v2.8.1/storageos_darwin_amd64 \
  && chmod +x storageos \
  && sudo mv storageos /usr/local/bin/ \
  && echo "CLI version installed:" \
  && storageos version
```

#### Windows

```bash
# PowerShell
Invoke-WebRequest https://github.com/storageos/go-cli/releases/download/v2.8.1/storageos_windows_amd64.exe -OutFile storageos.exe `
  ; Write-Host "Plugin version installed:" `
  ; .\storageos.exe version
```

#### Execute Commands Through The Ondat CLI Binary

- Once you have successfully installed the Ondat CLI, you can leverage [`kubectl port-forward`](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/) to establish a connection with your Ondat cluster in order to be able to execute commands.

```bash
# Change the "STORAGEOS_ENDPOINTS" to point to "localhost:5705".
export STORAGEOS_ENDPOINTS="localhost:5705"

# Use port forwarding to access the Ondat REST API locally.
kubectl port-forward service/storageos 5705 --namespace=storageos

# In a new shell, execute Ondat CLI commands to confirm that you can now interact with your Ondat cluster.
storageos version
```

## Usage

- Get the version of the CLI utility installed;

```bash
storageos version
```

- Get more information on the available commands in the CLI utility;

```bash
storageos help
```

```bash
Storage for Cloud Native Applications.

By using this product, you are agreeing to the terms of the the StorageOS Ltd. End
User Subscription Agreement (EUSA) found at: https://storageos.com/legal/#eusa

To be notified about stable releases and latest features, sign up at https://my.storageos.com.

Usage:
  storageos [command]

Available Commands:
  apply       Make changes to existing resources
  attach      Attach a volume to a node
  cordon      Marks a node as cordoned
  create      Create new resources
  delete      Delete resources in the cluster
  describe    Fetch extended details for resources
  detach      Detach a volume from its current location
  get         Fetch basic details for resources
  help        Help about any command
  nfs         Make changes and attach nfs volumes
  uncordon    Marks a node as uncordoned
  update      Make changes to existing resources
  version     View version information for the StorageOS CLI

Flags:
      --cache-dir string        set the directory used by the StorageOS CLI to cache data that can be used for future commands (default "/Users/rodney/Library/Caches/storageos")
  -c, --config string           specifies the config file path (default "/Users/rodney/Library/Application Support/storageos/config.yaml")
      --endpoints stringArray   set the list of endpoints which are used when connecting to the StorageOS API (default [http://localhost:5705])
  -h, --help                    help for storageos
  -n, --namespace string        specifies the namespace to operate within for commands that require one (default "default")
      --no-auth-cache           disable the CLI's caching of authentication sessions
  -o, --output string           specifies the output format (one of [json yaml text]) (default "text")
      --password string         set the StorageOS account password to authenticate with (default "storageos")
      --timeout duration        set the timeout duration to use for execution of the command (default 15s)
      --use-ids                 specify existing StorageOS resources by their unique identifiers instead of by their names
      --username string         set the StorageOS account username to authenticate as (default "storageos")

Additional help topics:
  storageos config-file View help information for using a configuration file
  storageos env         View documentation for configuration settings which can be set in the environment
  storageos exitcodes   View documentation for the exit codes used by the StorageOS CLI

Use "storageos [command] --help" for more information about a command.
```
