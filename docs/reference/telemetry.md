---
title: "Ondat Telemetry"
linkTitle: Ondat Telemetry
---

Ondat collects telemetry and error reports from Ondat clusters via two
different methods for two different purposes.

## Telemetry

* Telemetry is made up a DNS version check query and a once per day report.
* Error reporting is the sentry.io crash dump reporting.

## sentry.io

Ondat sends crash reports to [sentry.io](https://sentry.io). This
information helps our developers monitor and fix crashes. Information is sent
to sentry.io when a process inside the Ondat container
crashes.

* The crash report contains the signal that triggered the shutdown (e.g. SIGSEGV),
the exit code and whether or not the crash generated a core dump.

All Ondat clusters with a routable connection to the internet will send crash
reports to sentry.io over tcp/443. Ondat respects environment variables that
[ProxyFromEnvironment](https://golang.org/pkg/net/http/#ProxyFromEnvironment)
uses.

An exhaustive list of information included in the crash report is below:

* Ondat version
* Crash description string
* Anonymized Cluster ID
* Anonymized Node ID

## DNS Query

Ondat will perform a "latest version check" using a DNS query in order to
inform administrators that a new version is available. Ondat will also send
anonymized node IDs, cluster ID and Ondat version information to Ondat
using a DNS query. The information that we send in the query is encoded as well
as being anonymized. This query allows us to inform Cluster admins when
Ondat upgrades are available in the Ondat GUI and in the logs.

The DNS query includes:

* Anonymized Ondat Cluster ID
* Anonymized Ondat node ID
* Ondat version number

## Once Per Day Report

The once per day report contains information about the Ondat cluster and
Kubernetes versions to help Ondat focus our development efforts on the most
popular platforms. The once per day data is encrypted and sent to an Ondat
telemetry server so it is never processed outside of Ondat assets.

An exhaustive list of information included in the once per day report is below:

* api_call_metrics
* cluster_disable_crash_reporting
* cluster_disable_version_check
* cluster_log_format
* cluster_log_level
* cluster_tls_provided
* k8s_distribution
* k8s_in_k8s
* k8s_scheduler_extender_enabled
* k8s_version
* node_available_bytes
* node_capacity
* node_crash_files_on_disk
* node_created_at_time
* node_etcd_config
* node_etcd_namespacing_enabled
* node_etcd_tls_enabled
* node_free_bytes
* node_health
* node_http_tls_enabled
* node_id
* node_labels
* node_status
* node_storageos_version
* node_system_clock_time
* node_total_bytes
* node_version
* volume_fs_type
* volume_id
* volume_labels
* volume_master_attach
* volume_master_delete_deployment
* volume_master_detach
* volume_master_failover_deployment
* volume_master_promote
* volume_master_provision
* volume_master_recover_replica
* volume_master_trigger_rejoin
* volume_metrics
* volume_placement_strategy
* volume_provision_source_user_agent
* volume_replica_delete_deployment
* volume_replica_failover_deployment
* volume_replica_promote
* volume_replica_provision
* volume_replicas
* volume_replica_trigger_rejoin
* volume_size_bytes

## Disable Telemetry

It is possible to disable telemetry using the GUI, CLI, API, environment
variables or the Ondat Cluster Spec.

#### Ondat Cluster Spec

Disable telemetry explicitly through the configurable [spec parameters](
/docs/reference/operator/configuration) of the
StorageOSCluster custom resource.

#### Environment Variables

You can use the following environmental variables to disable or enable telemetry.

```bash
DISABLE_VERSION_CHECK   # Disable the DNS version check
DISABLE_TELEMETRY       # Disable the once per day reporting
DISABLE_ERROR_REPORTING # Disable sentry.io crash reports
```
