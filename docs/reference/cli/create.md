---
linkTitle: Create
---

# Create

```bash
$ storageos create --help

Create new resources

Usage:
  storageos create [command]

Available Commands:
  namespace    Provision a new namespace
  policy-group Provision a new policy group
  user         Create a new user account
  volume       Provision a new volume

Flags:
  -h, --help   help for create

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

Use "storageos create [command] --help" for more information about a command.
```

## create volume
```bash
$ storageos create volume --help

Provision a new volume

Usage:
  storageos create volume [flags]

Examples:

$ storageos create volume --description "This volume contains the data for my app" --fs-type "ext4" --labels env=prod,rack=db-1 --size 10GiB --namespace my-namespace-name my-app

$ storageos create volume --replicas 1 --namespace my-namespace-name my-replicated-app


Flags:
      --async                perform the operation asynchronously, using the configured timeout duration
      --cache                caches volume data (default true)
      --compress             compress data stored by the volume at rest and during transit
  -d, --description string   a human-friendly description to give the volume
  -f, --fs-type string       the filesystem to format the new volume with once provisioned (default "ext4")
  -h, --help                 help for volume
  -l, --labels strings       an optional set of labels to assign to the new volume, provided as a comma-separated list of key=value pairs
  -r, --replicas uint        the number of replicated copies of the volume to maintain
  -s, --size string          the capacity to provision the volume with (default "5GiB")
      --throttle             deprioritises the volumes traffic by reducing the rate of disk I/O

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

## create user
```bash
$ storageos create user --help

Create a new user account

Usage:
  storageos create user [flags]

Examples:

$ storageos create user --with-username=alice --with-admin=true 


Flags:
  -h, --help                      help for user
      --with-admin                control whether the user is given administrative privileges
      --with-groups stringArray   the list of policy groups to assign to the user
      --with-password string      the password to assign to the user. If not specified, this will be prompted for.
      --with-username string      the username to assign

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

## create namespace
```bash
$ storageos create namespace --help

Provision a new namespace

Usage:
  storageos create namespace [flags]

Examples:

$ storageos create namespace --labels env=prod,rack=db-1 my-namespace-name


Flags:
  -h, --help             help for namespace
  -l, --labels strings   an optional set of labels to assign to the new namespace, provided as a comma-separated list of key=value pairs

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

## create policy-group
```bash
$ storageos create policy-group --help

Provision a new policy group

Usage:
  storageos create policy-group [flags]

Examples:

$ storageos create policy-group -r 'namespace-name:*:r' -r 'namespace-name-2:volume:w'  my-policy-group-name
$ storageos create policy-group -r 'namespace-name:*:r,namespace-name-2:volume:w'  my-policy-group-name


Flags:
  -h, --help            help for policy-group
  -r, --rules strings   set of rules to assign to the new policy group, provided as a comma-separated list of namespace:resource:rw triples.

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
