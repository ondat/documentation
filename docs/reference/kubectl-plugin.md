---
title: "Ondat Kubectl Plugin"
linkTitle: "Ondat Kubectl Plugin"
weight: 1
---

## Overview

* The Ondat kubectl plugin is a utility tool that accepts imperative and declarative modes which allows cluster administrators to seamlessly install, troubleshoot, upgrade or uninstall Ondat. The plugin can also be used to connect and manage Ondat clusters on the [Ondat SaaS Platform](https://docs.ondat.io/docs/ondat-portal/).
  * The project repository is open source and can be located on [GitHub](https://github.com/storageos/kubectl-storageos).

### Install The Ondat Kubectl Plugin

#### Linux

```bash
curl --silent --show-error --location --output kubectl-storageos.tar.gz \
  https://github.com/storageos/kubectl-storageos/releases/download/v1.1.0/kubectl-storageos_1.1.0_linux_amd64.tar.gz \
  && tar --extract --file kubectl-storageos.tar.gz kubectl-storageos \
  && chmod +x kubectl-storageos \
  && sudo mv kubectl-storageos /usr/local/bin/ \
  && rm kubectl-storageos.tar.gz \
  && echo "Plugin version installed:" \
  && kubectl-storageos version
```

#### macOS (Darwin)

```bash
curl --silent --show-error --location --output kubectl-storageos.tar.gz \
  https://github.com/storageos/kubectl-storageos/releases/download/v1.1.0/kubectl-storageos_1.1.0_darwin_amd64.tar.gz \
  && tar --extract --verbose --file kubectl-storageos.tar.gz kubectl-storageos \
  && chmod +x kubectl-storageos \
  && sudo mv kubectl-storageos /usr/local/bin/ \
  && rm kubectl-storageos.tar.gz \
  && echo "Plugin version installed:" \
  && kubectl-storageos version
```

#### Windows

```bash
# PowerShell
Invoke-WebRequest https://github.com/storageos/kubectl-storageos/releases/download/v1.1.0/kubectl-storageos_1.1.0_windows_amd64.tar.gz -OutFile kubectl-storageos.tar.gz `
  ; tar -xf kubectl-storageos.tar.gz kubectl-storageos.exe `
  ; Remove-Item kubectl-storageos.tar.gz `
  ; Write-Host "Plugin version installed:" `
  ; .\kubectl-storageos.exe version
```

#### Others

* For more information on different binaries, supported architectures and checksum file verification, see the full page of [releases](https://github.com/storageos/kubectl-storageos/releases).

### Usage

* Get more version of the plugin installed;

```bash
kubectl storageos version
```

* Get more information on the available commands in the plugin;

```
kubectl storageos help
```

```
StorageOS kubectl plugin

Usage:
  kubectl-storageos [flags]
  kubectl-storageos [command]

Aliases:
  kubectl-storageos, kubectl storageos

Available Commands:
  bundle           Generate a support bundle
  completion       Generate completion script
  disable-portal   Disable StorageOS Portal Manager
  enable-portal    Enable StorageOS Portal Manager
  help             Help about any command
  install          Install StorageOS and (optionally) ETCD
  install-portal   Install StorageOS Portal Manager
  preflight        Test a k8s cluster for StorageOS pre-requisites
  uninstall        Uninstall StorageOS and (optionally) ETCD
  uninstall-portal Uninstall StorageOS Portal Manager
  upgrade          Ugrade StorageOS
  version          Show kubectl storageos version

Flags:
  -h, --help   help for kubectl-storageos

Use "kubectl-storageos [command] --help" for more information about a command.
```
