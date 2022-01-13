---
linkTitle: Update
---

# Update volume

```bash
Usage:
  storageos update volume [command]

Available Commands:
  description Updates a volume's description
  labels      Updates a volume's labels
  replicas    Updates a volume's target replica number
  size        Updates a volume's size

Flags:
  -h, --help   help for volume

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


## Update volume description

```bash
$ storageos update volume description -h
Updates a volume's description

Usage:
  storageos update volume description [volume name] [description] [flags]

Examples:

$ storageos update volume description my-volume-name "Volume for production IO" --namespace my-namespace-name
```

## Update volume labels

```bash
$ storageos update volume labels  -h
Updates a volume's labels

Usage:
  storageos update volume labels [volume name] [labels] [flags]

Examples:

$ storageos update volume labels my-volume-name tier=production,app=my-app --namespace my-namespace-name
$ storageos update volume labels my-volume-name --delete app=my-app --upsert tier=production --namespace my-namespace-name
$ storageos update volume labels my-volume-name --upsert tier=production --namespace my-namespace-name
$ storageos update volume labels my-volume-name --delete app=my-app --namespace my-namespace-name
```
## Update volume replicas

```bash
$ storageos update volume replicas   -h
Updates a volume's target replica number

Usage:
  storageos update volume replicas [volume name] [target number] [flags]

Examples:

$ storageos update volume replicas my-volume-name 2 --namespace my-namespace-name
```

## Update volume size

```bash
$ storageos update volume size  -h

Updates a volume's size

Usage:
  storageos update volume size [volume name] [size] [flags]

Examples:

$ storageos update volume size my-volume-name 42GiB --namespace my-namespace-name
$ storageos update volume size my-volume-name 42gib --namespace my-namespace-name
```
