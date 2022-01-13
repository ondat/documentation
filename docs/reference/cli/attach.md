---
linkTitle: Attach
---

# Attach

```bash
$ storageos attach --help

Attach a volume to a node

Usage:
  storageos attach [flags]

Examples:

$ storageos attach --namespace my-namespace-name my-volume my-node


Flags:
  -h, --help   help for attach

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
