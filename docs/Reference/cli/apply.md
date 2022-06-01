---
title: "Apply"
linkTitle: Apply
---

## Apply changes to resources

```bash
$ storageos apply --help
Make changes to existing resources

Usage:
  storageos apply [command]

Available Commands:
  licence     Apply a product licence to the cluster

Flags:
  -h, --help   help for apply

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

Use "storageos apply [command] --help" for more information about a command.
```

## Apply License

```bash
$ storageos apply licence --help

Apply a product licence to the cluster

Usage:
  storageos apply licence [flags]

Aliases:
  licence, license

Examples:

$ storageos apply licence --from-file <path-to-licence-file>

$ echo "<licence file contents>" | storageos apply licence --from-stdin 


Flags:
      --cas string         make changes to a resource conditional upon matching the provided version
      --from-file string   reads an Ondat product licence from a specified file path
      --from-stdin         reads an Ondat product licence from the standard input
  -h, --help               help for licence

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
