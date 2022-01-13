---
linkTitle: Diagnostic bundle
---

# Diagnostic bundle

Ondat can generate a cluster diagnostic bundle from the GUI or CLI under
user request. The bundle packages the information needed for the engineering
team to understand the context of your cluster and begin troubleshooting any
issues you may be experiencing.

## Generate Bundle

### CLI

The [CLI](/docs/reference/cli/_index) can generate
the bundle.

```bash
$ storageos get diagnostics
```
> The file generated is in the form of `diagnostics-${TIME_STAMP}.gz`

### GUI

Or you can use the [StoregeOS GUI](/docs/reference/gui).
1. Go to section "Cluster"
1. Press the button "DOWNLOAD DIAGNOSTICS".

## Data collected in the bundle

Most of the data collected in the bundle is regarding the state of the
Ondat cluster, however some other information regarding the infrastructure
is also gathered. The information is used to have a clear view of the cluster
where Ondat is running.

The bundle incorporates for each node:
- Ondat Daemonset Pod logs
- lshw
- dmesg (kernel logs)
- Ondat metadata for the ControlPlane and DataPlane

### Ondat metadata collected

- cluster metadata
- namespaces metadata
- nodes metadata
- volumes metadata
- capacity stats
- environment variables
- health

## Privacy

Ondat can only obtain the bundle if it is downloaded by the user and given
to our engineering team, or uploaded for analysis. The data received by
Ondat is private and never leaves nor will leave Ondat Inc.

The data contained in the cluster diagnostic bundle has the sole purpose of
helping customers troubleshoot their issues.
