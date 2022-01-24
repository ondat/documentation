---
title: "Support bundle"
linkTitle: Support bundle
---

The support bundle is a tool that gathers information both about Ondat and
the environment in which it is operating. It provides information about the
state and configuration of the cluster, nodes and other Kubernetes objects, as
well as system performance metrics.

The support bundle is an addition rather than a replacement to the [diagnostic
bundle](/docs/reference/bundles/diagnostic-bundle).

## Install Kubectl Ondat plugin

The support bundle is generated with the Ondat kubectl plugin, which can be
installed as follows:

```bash
$ curl -sL https://raw.githubusercontent.com/ondat/use-cases/main/scripts/storageos-support-bundle-install.sh | bash
```

If you prefer to run the installation commands individually, we provide them
here:


```bash
# Create a temporary directory in which to store the plugin binaries
TMP_DIR=$(mktemp -d /tmp/storageos-kubectl-plugin-XXXXX)

# Download the plugin binaries and extract to the temporary directory
TARGET="kubectl-storageos_linux_amd64.tar.gz"
curl -sSL -o kubectl-storageos.tar.gz https://github.com/storageos/storageos.github.io/raw/master/sh/$TARGET
tar -xf kubectl-storageos.tar.gz -C $TMP_DIR/

# Clean up the tar file
rm -f kubectl-storageos.tar.gz

# Add executable permissions for the plugin binaries and move into system path
# For details of the bundle-generation tool's functionality, visit:
#https://docs.storageos.com/docs/bundles/support-bundle/
chmod +x $TMP_DIR/bin/kubectl-storageos-bundle
sudo mv $TMP_DIR/bin/kubectl-storageos-bundle /usr/local/bin/
```

> For MacOS build, use `TARGET=kubectl-storageos_darwin_amd64.tar.gz`

## Generate Bundle

To generate a bundle, use the following command, the specification of which can
be viewed and edited by obtaining the `bundle-configuration.yaml` file, which
is publicly available.

Ondat is usually installed in the kube-system namespace. If you have
installed Ondat in a different namespace please replace the namespace in
the storage bundle config as below.

```bash
STORAGEOS_NS=my-namespace
curl -s https://raw.githubusercontent.com/ondat/use-cases/main/scripts/bundle-configuration.yaml | sed "s/kube-system/$STORAGEOS_NS/g" > /tmp/storageos-kubectl-config.yaml
kubectl storageos bundle /tmp/storageos-kubectl-config.yaml
```
**Please note** that if you have a custom selector for your worker nodes you
should update the bundle-configuration.yaml under
`spec.collectors.run.nodeselector` to reflect this.

Note also that the bundle tool expects there to be an Ondat CLI running in
kube-system as a Pod with the label `run=cli`. The tool will exec into this pod
to get information from the Ondat API. If the Ondat CLI Pod does not
match this criteria, you can either pull the YAML file and change the selector
in the file, or add the label to the Pod. You can run the cli container
following these [instructions](/docs/reference/cli/_index#run-cli-as-a-container).

### Data collected in the bundle

The data collected covers both the state of the Ondat cluster, and in
particular information regarding the infrastructure on which Ondat is
operating. It includes:

- Ondat CLI information
- Ondat Operator logs
- Ondat logs
- Cluster metadata
- Cluster resources (DaemonSets, Events, Services, Pods, etc.)
- Backend disk configuration and performance statistics
- Load average
- Network checks across Ondat nodes and ports
- Running processes

## Privacy

Ondat can only obtain the bundle if it is downloaded by the user and given
to our engineering team, or uploaded for analysis. The data received by
Ondat is private and never leaves nor will leave Ondat Inc.

The data contained in the support bundle has the sole purpose of helping
customers troubleshoot their issues.
