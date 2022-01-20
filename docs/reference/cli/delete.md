---
title: "Delete"
linkTitle: Delete
---

```bash
$ storageos delete -h

Delete resources in the cluster

Usage:
  storageos delete [command]

Available Commands:
  namespace    Delete a namespace
  node         Delete a node
  policy-group Delete a policy group
  user         Delete a user
  volume       Delete a volume. By default the target volume must be online. If the volume is offline then the request must specify that an offline delete is desired.

Flags:
  -h, --help   help for delete

Global Flags:
      --cache-dir string        set the directory used by the Ondat CLI to cache data that can be used for future commands (default "/root/.cache/storageos")
  -c, --config string           specifies the config file path (default "/root/.config/storageos/config.yaml")
      --endpoints stringArray   set the list of endpoints which are used when connecting to the Ondat API (default [http://localhost:5705])
  -n, --namespace string        specifies the namespace to operate within for commands that require one (default "default")
      --no-auth-cache           disable the CLI's caching of authentication sessions
  -o, --output string           specifies the output format (one of [json yaml text]) (default "text")
      --password string         set the Ondat account password to authenticate with (default "storageos")
      --timeout duration        set the timeout duration to use for execution of the command (default 15s)
      --use-ids                 specify existing Ondat resources by their unique identifiers instead of by their names
      --username string         set the Ondat account username to authenticate as (default "storageos")

Use "storageos delete [command] --help" for more information about a command.
```

## delete volume

```bash
$ storageos delete volume --help

Delete a volume. By default the target volume must be online. If the volume is offline then the request must specify that an offline delete is desired.

Usage:
  storageos delete volume [volume name] [flags]

Examples:

$ storageos delete volume my-test-volume my-unneeded-volume

$ storageos delete volume --namespace my-namespace my-old-volume


Flags:
      --async            perform the operation asynchronously, using the configured timeout duration
      --cas string       make changes to a resource conditional upon matching the provided version
  -h, --help             help for volume
      --offline-delete   request deletion of an offline volume. Volume data is not removed until the node reboots

Global Flags:
      --cache-dir string        set the directory used by the Ondat CLI to cache data that can be used for future commands (default "/root/.cache/storageos")
  -c, --config string           specifies the config file path (default "/root/.config/storageos/config.yaml")
      --endpoints stringArray   set the list of endpoints which are used when connecting to the Ondat API (default [http://localhost:5705])
  -n, --namespace string        specifies the namespace to operate within for commands that require one (default "default")
      --no-auth-cache           disable the CLI's caching of authentication sessions
  -o, --output string           specifies the output format (one of [json yaml text]) (default "text")
      --password string         set the Ondat account password to authenticate with (default "storageos")
      --timeout duration        set the timeout duration to use for execution of the command (default 15s)
      --use-ids                 specify existing Ondat resources by their unique identifiers instead of by their names
      --username string         set the Ondat account username to authenticate as (default "storageos")
```

## delete user
```bash
$ storageos delete user --help

Delete a user

Usage:
  storageos delete user [user name] [flags]

Examples:

$ storageos delete user my-unneeded-user
$ storageos delete user --use-ids my-user-id


Flags:
      --cas string   make changes to a resource conditional upon matching the provided version
  -h, --help         help for user

Global Flags:
      --cache-dir string        set the directory used by the Ondat CLI to cache data that can be used for future commands (default "/root/.cache/storageos")
  -c, --config string           specifies the config file path (default "/root/.config/storageos/config.yaml")
      --endpoints stringArray   set the list of endpoints which are used when connecting to the Ondat API (default [http://localhost:5705])
  -n, --namespace string        specifies the namespace to operate within for commands that require one (default "default")
      --no-auth-cache           disable the CLI's caching of authentication sessions
  -o, --output string           specifies the output format (one of [json yaml text]) (default "text")
      --password string         set the Ondat account password to authenticate with (default "storageos")
      --timeout duration        set the timeout duration to use for execution of the command (default 15s)
      --use-ids                 specify existing Ondat resources by their unique identifiers instead of by their names
      --username string         set the Ondat account username to authenticate as (default "storageos")
```

## delete policy-group
```bash
$ storageos delete policy-group --help

Delete a policy group

Usage:
  storageos delete policy-group [policy group name] [flags]

Examples:

$ storageos delete policy-group my-unneeded-policy-group
$ storageos delete policy-group --use-ids my-policy-group-id


Flags:
      --cas string   make changes to a resource conditional upon matching the provided version
  -h, --help         help for policy-group

Global Flags:
      --cache-dir string        set the directory used by the Ondat CLI to cache data that can be used for future commands (default "/root/.cache/storageos")
  -c, --config string           specifies the config file path (default "/root/.config/storageos/config.yaml")
      --endpoints stringArray   set the list of endpoints which are used when connecting to the Ondat API (default [http://localhost:5705])
  -n, --namespace string        specifies the namespace to operate within for commands that require one (default "default")
      --no-auth-cache           disable the CLI's caching of authentication sessions
  -o, --output string           specifies the output format (one of [json yaml text]) (default "text")
      --password string         set the Ondat account password to authenticate with (default "storageos")
      --timeout duration        set the timeout duration to use for execution of the command (default 15s)
      --use-ids                 specify existing Ondat resources by their unique identifiers instead of by their names
      --username string         set the Ondat account username to authenticate as (default "storageos")

```

## delete node
```bash
$ storageos delete node --help

Delete a node

Usage:
  storageos delete node [node name] [flags]

Examples:

$ storagoes delete node my-old-node


Flags:
      --async        perform the operation asynchronously, using the configured timeout duration
      --cas string   make changes to a resource conditional upon matching the provided version
  -h, --help         help for node

Global Flags:
      --cache-dir string        set the directory used by the Ondat CLI to cache data that can be used for future commands (default "/root/.cache/storageos")
  -c, --config string           specifies the config file path (default "/root/.config/storageos/config.yaml")
      --endpoints stringArray   set the list of endpoints which are used when connecting to the Ondat API (default [http://localhost:5705])
  -n, --namespace string        specifies the namespace to operate within for commands that require one (default "default")
      --no-auth-cache           disable the CLI's caching of authentication sessions
  -o, --output string           specifies the output format (one of [json yaml text]) (default "text")
      --password string         set the Ondat account password to authenticate with (default "storageos")
      --timeout duration        set the timeout duration to use for execution of the command (default 15s)
      --use-ids                 specify existing Ondat resources by their unique identifiers instead of by their names
      --username string         set the Ondat account username to authenticate as (default "storageos")
```

## delete namespace
```bash
$ storageos delete namespace --help

Delete a namespace

Usage:
  storageos delete namespace [namespace name] [flags]

Examples:

$ storageos delete namespace my-unneeded-namespace
$ storageos delete namespace --use-ids my-namespace-id


Flags:
      --cas string   make changes to a resource conditional upon matching the provided version
  -h, --help         help for namespace

Global Flags:
      --cache-dir string        set the directory used by the Ondat CLI to cache data that can be used for future commands (default "/root/.cache/storageos")
  -c, --config string           specifies the config file path (default "/root/.config/storageos/config.yaml")
      --endpoints stringArray   set the list of endpoints which are used when connecting to the Ondat API (default [http://localhost:5705])
  -n, --namespace string        specifies the namespace to operate within for commands that require one (default "default")
      --no-auth-cache           disable the CLI's caching of authentication sessions
  -o, --output string           specifies the output format (one of [json yaml text]) (default "text")
      --password string         set the Ondat account password to authenticate with (default "storageos")
      --timeout duration        set the timeout duration to use for execution of the command (default 15s)
      --use-ids                 specify existing Ondat resources by their unique identifiers instead of by their names
      --username string         set the Ondat account username to authenticate as (default "storageos")
```
