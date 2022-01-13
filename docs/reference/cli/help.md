---
linkTitle: Help
---

# Help

```bash
$ storageos help

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
      --cache-dir string        set the directory used by the Ondat CLI to cache data that can be used for future commands (default "/root/.cache/storageos")
  -c, --config string           specifies the config file path (default "/root/.config/storageos/config.yaml")
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
