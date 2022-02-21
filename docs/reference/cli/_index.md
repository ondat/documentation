---
title: "Command Line Interface"
linkTitle: CLI
---

The `storageos` command-line interface (CLI) is used to manage cluster-wide
configuration.

It is highly recommended to install the CLI, since it can be used to generate a
lot of useful information about your Ondat cluster and significantly speed
up resolution times for support issues.

## Installation

```bash
# linux/amd64
curl -sSLo storageos \ 
    https://github.com/storageos/go-cli/releases/download/v2.6.0/storageos_linux_amd64 \
    && chmod +x storageos \
    && sudo mv storageos /usr/local/bin/

# MacOS
curl -sSLo storageos \
    https://github.com/storageos/go-cli/releases/download/v2.6.0/storageos_darwin_amd64 \
    && chmod +x storageos \
    && sudo mv storageos /usr/local/bin/
```

You will need to provide the correct credentials to connect to the API. The
default installation uses the `storageos-api` Secret to generate the first
admin user. By default, it creates a single user with username `storageos` and
password `storageos`:

```bash
export STORAGEOS_USERNAME=storageos
export STORAGEOS_PASSWORD=storageos
export STORAGEOS_ENDPOINTS=10.1.5.249:5705
```

### Run the CLI as a deployment in your cluster

This is a preferred installation method, since our support bundle generation
software can automatically detect a deployment called "cli" and warn you if you
do not have the CLI installed. You can run CLI commands with `kubectl exec` on
your cli container.

`kubectl apply -f` the below YAML manifest to install.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cli
  namespace: storageos
  labels:
    app: storageos-cli
    kind: storageos
    app.kubernetes.io/part-of: storageos
    app.kubernetes.io/component: storageos-cli
spec:
  replicas: 1
  selector:
    matchLabels:
      app: storageos-cli
  template:
    metadata:
      name: storageos-cli
      labels:
        app: storageos-cli
    spec:
      containers:
      - image: storageos/cli:< param latest_cli_version >
        command:
          - "/bin/sh"
          - "-c"
          - "while true; do sleep 3600; done"
        imagePullPolicy: IfNotPresent
        name: cli
        ports:
        - containerPort: 5705
        env:
        - name: STORAGEOS_USERNAME
          value: storageos
        - name: STORAGEOS_PASSWORD
          value: storageos
        - name: STORAGEOS_ENDPOINTS
          value: storageos:5705
      restartPolicy: Always
```

### Run CLI as a container

You can also run the cli as a container in your Kubernetes cluster. Then exec
into it to run commands.

```bash
kubectl -n storageos run \
    --image storageos/cli:< param latest_cli_version > \
    --restart=Never                          \
    --env STORAGEOS_ENDPOINTS=storageos:5705 \
    --env STORAGEOS_USERNAME=storageos       \
    --env STORAGEOS_PASSWORD=storageos       \
    --command cli                            \
    -- /bin/sh -c "while true; do sleep 100000; done"
```

## Usage

```bash
$ storageos
Storage for Cloud Native Applications.

By using this product, you are agreeing to the terms of the the Ondat Ltd. End
User Subscription Agreement (EUSA) found at: https://storageos.com/legal/#eusa

To be notified about stable releases and latest features, sign up at https://my.storageos.com.

Usage:
  storageos [command]

Available Commands:
  apply       Make changes to existing resources
  attach      Attach a volume to a node
  create      Create new resources
  delete      Delete resources in the cluster
  describe    Fetch extended details for resources
  detach      Detach a volume from its current location
  get         Fetch basic details for resources
  help        Help about any command
  nfs         Make changes and attach nfs volumes
  update      Make changes to existing resources
  version     View version information for the Ondat CLI

Flags:
      --cache-dir string        set the directory used by the Ondat CLI to cache data that can be used for future commands (default "/home/user/.cache/storageos")
  -c, --config string           specifies the config file path (default "/home/user/.config/storageos/config.yaml")
      --endpoints stringArray   set the list of endpoints which are used when connecting to the Ondat API (default [http://localhost:5705])
  -h, --help                    help for storageos
  -n, --namespace string        specifies the namespace to operate within for commands that require one (default "default")
      --no-auth-cache           disable the CLI's caching of authentication sessions
  -o, --output string           specifies the output format (one of [json yaml text]) (default "text")
      --password string         set the Ondat account password to authenticate with (default "storageos")
      --timeout duration        set the timeout duration to use for execution of the command (default 15s)
      --use-ids                 specify existing Ondat resources by their unique identifiers instead of by their names
      --username string         set the Ondat account username to authenticate as (default "storageos")

Additional help topics:
  storageos config-file View help information for using a configuration file
  storageos env         View documentation for configuration settings which can be set in the environment
  storageos exitcodes   View documentation for the exit codes used by the Ondat CLI

Use "storageos [command] --help" for more information about a command.
```

## Formatting CLI Output

Ondat CLI output can be formatted using the `--output` option. The strings
that are passed to `--output` are 'json', 'yaml' or 'text'.

## Cheatsheet

| Command       | Subcommand                                                          | Description                             |
| ------------- | --------------------------------------------------------------------| --------------------------------------- |
| `apply`       | `licence`                                                           | Make changes to existing resources.     |
| `attach`      |                                                                     | Attach Volume to a node.                |
| `create`      | `namespace, policy-group, user, volume`                             | Create resources.                       |
| `delete`      | `namespace, node, policy-group, user, volume`                       | Delete resources.                       |
| `describe`    | `cluster, licence, namespace, node, policy-group, user, volume`     | Show detailed view of resources.        |
| `detach`      |                                                                     | Detach volume from a node.              |
| `get`         | `cluster, diagnostics, namespace, node, policy-group, user, volume` | List resources.                         |
| `help`        |                                                                     | Help                                    |
| `nfs`         | `attach, endpoint, exports`                                         | Make changes to and attach nfs volumes  |
| `update`      | `volume`                                                            | Make changes to existing resources      |
| `version`     |                                                                     | Show CLI version.                       |

[Source is available on GitHub](https://github.com/storageos/go-cli).
