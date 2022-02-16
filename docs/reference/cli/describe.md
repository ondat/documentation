---
title: "Describe"
linkTitle: Describe
---

```bash
$ storageos describe --help

Fetch extended details for resources

Usage:
  storageos describe [command]

Available Commands:
  cluster      Retrieve detailed information for the current cluster
  licence      Fetch current licence configuration details
  namespace    Retrieve detailed information for one or many namespaces
  node         Retrieve detailed information for nodes in the cluster
  policy-group Show detailed information for policy groups
  user         Show detailed information for users
  volume       Show detailed information for volumes

Flags:
  -h, --help   help for describe

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

Use "storageos describe [command] --help" for more information about a command.
```

## describe cluster

```bash
$ storageos describe cluster --help

Retrieve detailed information for the current cluster

Usage:
  storageos describe cluster [flags]

Aliases:
  cluster, nodes

Examples:

$ storageos describe cluster


Flags:
  -h, --help   help for cluster

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

## describe license

```bash
$ storageos describe license --help

Fetch current licence configuration details

Usage:
  storageos describe licence [flags]

Aliases:
  licence, license

Examples:

$ storageos describe licence


Flags:
  -h, --help   help for licence

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

## describe namespace

```bash
$ storageos describe namespace --help

Retrieve detailed information for one or many namespaces

Usage:
  storageos describe namespace [flags]

Aliases:
  namespace, namespaces

Examples:

$ storageos describe namespace my-namespace-name
$ storageos describe namespace --use-ids my-namespace-id
$ storageos describe namespaces


Flags:
  -h, --help   help for namespace

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

## describe node

```bash
$ storageos describe node --help

Retrieve detailed information for nodes in the cluster

Usage:
  storageos describe node [node names...] [flags]

Aliases:
  node, nodes

Examples:

$ storageos describe node my-node-name


Flags:
  -h, --help                   help for node
  -l, --selector stringArray   filter returned results by a set of comma-separated label selectors

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

## describe policy-group

```bash
$ storageos describe user --help

Show detailed information for policy groups

Usage:
  storageos describe policy-group [policy group names...] [flags]

Aliases:
  policy-group, policy-groups

Examples:

$ storageos describe policy-groups
$ storageos describe policy-group my-policy-group-name


Flags:
  -h, --help   help for policy-group

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

## describe user

```bash
$ storageos describe user --help

Show detailed information for users

Usage:
  storageos describe user [user names...] [flags]

Aliases:
  user, users

Examples:

$ storageos describe users
$ storageos describe user my-username
$ storageos describe user my-username-1 my-username-2
$ storageos describe user --use-ids my-userid
$ storageos describe user --use-ids my-userid-1 my-userid-2


Flags:
  -h, --help   help for user

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

## describe volume

```bash
$ storageos describe volume --help

Show detailed information for volumes

Usage:
  storageos describe volume [volume names...] [flags]

Aliases:
  volume, volumes

Examples:

$ storageos describe volumes

$ storageos describe volume --namespace my-namespace-name my-volume-name


Flags:
  -A, --all-namespaces         retrieves volumes from all accessible namespaces. This option overrides the namespace configuration
  -h, --help                   help for volume
  -l, --selector stringArray   filter returned results by a set of comma-separated label selectors

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
