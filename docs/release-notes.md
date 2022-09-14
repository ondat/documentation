---
title: "Release Notes"
linkTitle: Release Notes
weight: 150
description: >
  Ondat release notes on new features, fixes and changes.
---

We recommend always using "tagged" versions of Ondat rather than "latest",
and to perform upgrades only after reading the release notes.

The latest tagged release is `2.8.3`. For
installation instructions see our
[Install](/docs/install/) page.

The latest CLI release is `2.8.3`, available from
[GitHub](https://github.com/storageos/go-cli/releases).

# Upgrading

To upgrade from version 1.x to 2.x, contact Ondat [support](/docs/support) for assistance.

## 2.8.3 - Release 2022-09-14

### New

Data Plane

* Added support for AWS Bottlerocket
* Added check for whether the block device directory (usually `/var/lib/storageos/volumes`) supports creation of devices, and enable it if it is not already

Kubernetes

* The scheduler extender, that attempts to place workloads on the same nodes as volumes, can now be disabled

### Fixed

Data Plane

* Increased the LIO_DEVICE_TIMEOUT_SECS to 300 seconds (5 minutes) and the LIO_RETRY_LOOP_DURATION_SECS to 240 seconds (4 minutes). This provides additional flexibility for environments experiencing resource contention
* Added environment variables so time-outs can be adjusted and tuned
* Fixed spelling mistake in alert log messages
* Improved the clarity of the log messages which alert users that IO to the backend disk (fdatasync, preadv, pwritev and fallocate) is running unusually slowly
* Fixed an issue wherein creating a Ondat block device could erroneously fail because we'd fail to wait for the underlying kernel device to be available

Kubernetes

* The following fixes apply to k8s clusters running v1.23, v1.24 and v1.25, the bugs did not apply to older cluster versions
  * api-manager will now have permissions to use `podsecuritypolicies`
  * api-manager now has the expected resource limits
  * api-manager will no longer run as root
  * api-manager pods will now be spread across nodes

Control Plane

* The control plane will now crash loop less when its pod is restarted

## 2.8.2 - Release 2022-08-12

### Fixed

Data Plane

* Fixed a bug that would cause the Data Plane to crash due to a timing issue.

## 2.8.1 - Release 2022-08-02

### New

k8s

* Operator:
  * Install snapshot controller and related CRDs if not present
  * Pod Disruption Budget support for k8s v1.25
* Improve logging on kubectl plugin

Data Plane

* Warn that filesystem might go read-only after a failed write or sync SCSI command. The log of interest is: `"SCSI command failed - if the block device is mounted the filesystem may go read-only".`
* Log when the average IO service time from the mount node is greater than 2 seconds. We log the following message on a per volume basis with exponential backoff: `"it is taking unsually long to send and receive IO from the presentation node"`. Metrics are included in the log message.
  * Note: this measurement is tracking the time it takes to send the IO over the network to the master and any replicas and for the IO to be committed and the response sent back to the mount node.
* Log when the average IO service time from the master node to its replica is greater than 2 seconds. We log the following message, on a per replica basis with exponential backoff: "it is taking unsually long to send and receive IO from the master deployment to its replica". Metrics are included in the log message. Note: this measurement is tracking the time it takes to send the IO over the network to the replica and for the IO to be committed and the response sent back to the mount node.
* Log when it takes more than 1 second to commit a write, read, sync or unmap to disk. Logs of interest are of the format `"X operation took longer than Yms to complete completion_time=Zms".`

Control Plane

* Automatically round up storage requests to align with blocksize, instead of rejecting requests

### Fixed

k8s

* Fixed an issue where Portal Manager would not work if installed in a namespace that was not `storageos`
* Fixed an issue where CSI requests would occasionally not be serviced
* Fixed an issue on GKE where some pods would not be scheduled if there was no resource quota
* Fixed a bug where the operator would attempt to delete snapshot related CRs when the CRD did not exist
* Fixed an issue where default containers were not correctly marked

Control Plane

* Reduced the amount of crash loop backoffs when installing via the helm chart
* Reduced the impact of ListVolumes on etcd (significantly, in the case of clusters with lots of volumes)
* Fixed an issue where formatting would timeout due to large TRIM writes being sent across the network
* Fixed an issue where volume deployments would all be scheduled on the same nodes when deploying multiple PVC at the same time

Data Plane

* Fix `Convert<>` and add support for `uint16_t`.
* Fix `Volume::GetConsumerCount`
* Improve error message when a write/unmap SCSI command is not committed to the backend disk: `"a consumer IO was not committed to rdbplugin because its transaction ID lost. This could mean there are two consumers with the same transaction ID (bad); the CP has forgotten to increment the consumer count in between remounts of the volume (bad) or it could indicate that a retry of this IO operation has overtaken a previous IO attempt (normally indicative of a very slow/flaky network and/or disk)."`

## 2.8.0 - Release 2022-06-29

> 💡 For Ondat 2.8.0, we recommend having at least a 5 node cluster when running etcd within Kubernetes, as we recommend running etcd with 5 replicas.

### New

k8s

* Etcd in Production: We have added support for putting ETCD in your cluster in a production environment
* Modified CSI provisioner to work with Snapshots
* Ondat volumes metrics exporter: we have added a Prometheus endpoint to allow users to view metrics for Ondat Volumes

Control Plane

* We have relaxed some Ondat specific security checks for the ReadWriteOnce node volumes that we were doing in the control plane ahead of the new volume mode ReadWriteOncePod which is being introduced in k8s 1.22. This will align the Ondat RWO volumes with the spec and we will in a future release also implement support for [RWOP](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) for users that wish to implement these existing controls.
  * Please note that the relaxation of these security checks could mean that Deployment objects using RWO volumes (if a rolling strategy is used for example) will be able to mount the volume concurrently on the same node, for this reason we suggest users are creating workloads using stateful sets or use RWX volumes for these deployments.

Data Plane

* Snapshot GA: we added the Snapshot feature to allow users to back up their Ondat data outside of their Kubernetes clusters in conjunction with a backup solution

Portal Manager

* Automatic licencing: we added a feature to allow automatic deployment of licence to your cluster when you connect to our Ondat SaaS Platform

### Fixed

k8s

* Fixed a bug where the StorageOS operator would occasionally restart

## 2.7.0 - Released 2022-04-11

### New

k8s & Orchestrator Rolling Upgrade

* Tech Preview: Kubernetes rolling upgrade for AWS EKS, Google Anthos, Google GKE, Microsoft Azure, Openshift and Rancher
  > ⚠️ This is a tech preview, we only recommend using this feature on your test clusters

Operator

* Updated memory limit
* Introduced topology spread constraint with `ScheduledAnyway`

API Manager

* Adds a feature so when a PVC is not found scheduling will not be blocked

Control Plane

* Set `Only_Numeric_Owners` to true on NFSv4 setting on Ganesha

Data Plane

* Removed support for FUSE. Ondat now only supports TCMU. `target_core_user` must now be used. Read [System Configuration](https://docs.ondat.io/docs/prerequisites/systemconfiguration/) for more information
* Rewrote the RPC interface between the Control Plane and the Data Plane. All of the old `ctl` tools have been removed
* Removed the 32-bit mappings and uses the UUIDs passed by the CP directly to address presentations and deployments
  > ⚠️ If you decide to upgrade to 2.7.0 and want to downgrade, you can only roll back to 2.6.0, not earlier versions. Roll back instruction can be found [here](/docs/operations/downgrade-ondat-2.7-to-2.6)

### Fixed

Operator

* Fixed a bug that sometimes caused the operator to enter a deadlock state after Ondat cluster CR object deletion

Control Plane

* Fixed an issue where Ondat was not able to unmount volumes in rare instances, then occasionally causing volumes to become unhealthy
* Fixed an issue that caused replicas to go into the “unknown” state during failover in somne rare instances
* Fixed an issue to now display output all dataplane logs even if they don't have the expected syntax
* Fixed an issue so Ondat would speculatively configure the replica in the dataplane before we advertise ourselves to the master
* Fix an issue where goroutines attempting to dial remote nodes could be blocked
* Fix an issue so Ondat volume would remain mounted and online during temporary network issues when pod is on remote, master and replica

Data Plane

* Fix non-null terminated buffer which could lead to garbled logs
* Fix client-server network to improve robustness

## 2.6.0 - Released 2022-02-14

### New

Portal Manager:

* Initial release of the Portal Manager, which supports the connection to Ondat
  SaaS Platform.

Kubectl Plugin:

* We have added a `--dry-run` flag into install command, so you can view the
  installation manifests written locally to `./storageos-dry-run/`.
* We have added capability for conducting an airgapped installation. The new
  options can also be used outside of an airgapped cluster.

Operator:

* We have defined the resource requests and resource limits for the Ondat
  components (csi-attacher, csi-provisioner, csi-resizer, api-manager,
  cluster-operator and ondat-scheduler).

Kubernetes:

* Ondat supports Kubernetes v1.23

Components

* We have added a new component called Node Guard that once enabled allows
  you to do rolling upgrades to the orchestrator without any downtime. This
  component is disabled by default and we do not recommend using the feature
  for production workloads as it is a technical preview feature.
  
## 2.5.0 - Released 2021-12-06

### Fixed

Dataplane:

* Deadlock with unordered UNMAP commands.
* Spurious log message when detaching a volume - you would often see a spurious
  warning message “missing fs configuration for presentation_id=2001". We've
  fixed the issue that led to this log message, by ensuring deletion of LUN
  (Logical Unit Number).
* Stop potential shutdown hangs - `directfs initiator` could restart
  connections after shutdown has been requested. This race condition has been
  removed.
* Misleading log message when `SetVolumeConsumerCount` is called - log message
  now only sent in correct scenarios.
* Volume backup tool in disaster recovery scenarios - the volume backup tool is
  used to extract volume data in disaster recovery scenarios. There was an
  issue that prevented the tool from running whilst the Dataplane was running.
  This has been fixed.

### New

Dataplane:

* Faster replica syncing - new replicas can be provisioned faster and rejoining
  replicas sync faster. Non-contiguous data regions are collated into the same
  RPC. Ondat now syncs multiple regions concurrently maximising the network
  bandwidth.
* Improved network performance - Up to 2.3 times faster speed and even higher
  on high-latency networks.
* Improved error-handling mechanism for synchronise cache commands - we have
  ensured error messages are propagated when SYNCHRONIZE_CACHE_16 commands
  fail.

Control Plane:

* [Topology-Aware Placement](/docs/reference/tap) is a feature
  that enforces placement of data across failure domains to guarantee high
  availability.
* Track logs from control plane to data plane with extra details.
* The command-line tool can now display the availability zone of each of the volume's
  deployments.

Kubernetes:

* New [kubectl plugin](/docs/reference/kubectl-plugin) to
  manage Ondat.
* Upgrades to the operator and improved development speed - StorageOS cluster
  status now reflects cluster deployment status. Users can now change log-level
  port to new operator and we have given users increased flexibility for users
  to configure StorageOS images.

## 2.4.4 - Released 2021-09-08

### Fixed

* controlplane: Fix an issue with timeouts when opening gRPC connections to
  other nodes in the cluster.
* controlplane: Changes to GUI licensing workflow - See our [Licensing
  page](/docs/reference/licence)
* dataplane: Fix an issue where failed IO network connections could be
  erroneously restarted while we are trying to shutdown.
* k8s: Leader election requires ability to patch events.
* k8s: Node label sync could fail to apply updated label.

## v2.4.2 - Released 2021-07-15

### Fixed

* controlplane: Improve error message when unable to set the cluster-wide log
  level on an individual node.

* dataplane: Fix rare assert when retrying some writes under certain conditions.
* dataplane: Log format string safety improvements.
* dataplane: Backuptool reliability improvements.

* k8s/cluster-operator: Allow api-manager to patch events for leader election.

## v2.4.1 - Released 2021-06-30

### New

* Cluster-wide log level configuration via Custom Resource.

### Fixed

* controlplane: Improve error message during failed `--label` argument parsing.
* controlplane: Double-check the OS performs the NFS mount as directed, and
  unmount on error.
* controlplane: Improved FSM and sync CC logging.

* dataplane: Log message quality, quantity and visibility improvements.
* dataplane: Volume backup tool error reporting improvements.

* k8s: Pod scheduler fixes.

## v2.4.0 - Released 2021-05-27

This release adds production-grade [encryption at rest](/docs/reference/encryption) for Ondat volumes, as well as:

* [Fencing](/docs/concepts/fencing)
* [TRIM](/docs/operations/trim)
* [Failure modes](/docs/concepts/replication#failure-modes)
* [Kubernetes object sync](/docs/reference/kubernetes-object-sync)

Note: v2.4.0 _requires_ Kubernetes 1.17 or newer.

### New

* Volume encryption-at-rest.
* Fencing support.
* Block trim support.
* Kubernetes label sync.
* Kubernetes node and namespace delete sync.
* Failure tolerance threshold support.

### Fixed

* controlplane/api: Compression is not disabled by default when provisioning
  volumes via the API.
* controlplane/api: Spec has incorrect response body for partial bundle.
* controlplane/csi: Error incorrectly returned when concurrent namespace
  creation requests occur.
* controlplane/diagnostics: GetDiagnostics RPC response does not indicate if
  node timed out collecting some data.
* controlplane/diagnostics: Invalid character '\u0080' looking for beginning of
  value via CLI when a node is down.
* controlplane/diagnosticutil: Include attachment type in unpacking local
  volumes.
* controlplane/diagnotics: Node timing out during local diagnostics is missing
  logs.
* controlplane/healthcheck: Combined sources fires callback in initialisation.
* controlplane/volumerpc: "Got unknown replica state 0" discards results.

* dataplane/fix: Check blob writes don't exceed internal limit.
* dataplane/fix: Checking the return code of InitiatorAddConnection().
* dataplane/fix: Director signal hander thread is not joined.
* dataplane/fix: Don't block I/O when many retries are in progress.
* dataplane/fix: gRPC API robustness improvements.
* dataplane/fix: Initiator needs to include the node UUID in Endpoint.
* dataplane/fix: Low-level I/O engines don't propagate IO failures via Wait().
* dataplane/fix: Log available contextual information where possible.
* dataplane/fix: Ensure BackingStore is not deleted twice.
* dataplane/fix: Serialise LIO create/delete operations to avoid kernel bug.
* dataplane/fix: Dataplane shutdown time can exceed 10 seconds.
* dataplane/fix: Fix non-threadsafe access on TCMU device object.
* dataplane/fix: Don't hold lock unecessarily in Rdb::Reap.

* k8s/api-manager: First ip octet should not be 0, 127, 169 or 224.
* k8s/api-manager: Keygen should only operate on Ondat PVCs.

* k8s/cluster-operator: Add perm to allow VolumeAttachment finalizer removal.
* k8s/cluster-operator: Fix apiManagerContainer tag in v1 deploy CRD.
* k8s/cluster-operator: Fix docker credentials check.
* k8s/cluster-operator: Fix ServiceAccountName in the OLM bundle.
* k8s/cluster-operator: Set webhook service-for label to be unique.

### Improved

* controlplane/api: Make version provided consistent for NFS/Host attach
  handler.
* controlplane/attachtracker: Cleanup NFS mounts at shutdown.
* controlplane/build: Migrate to go modules for dependency management.
* controlplane/build: Use sentry prod-url if build branch has "release" prefix.
* controlplane/cli: Colour for significant feedback.
* controlplane/cli: Update node must set compute only separately to other
  labels.
* controlplane/cli: Warn user that updating labels action can be reverted.
* controlplane/csi: Bound request handlers with timeout similar to HTTP API.
* controlplane/csi: Remove error obfuscation and clarify log messages.
* controlplane/csi: Stop logging not found.
* controlplane/dataplane: Remove UUID mappings during failed presentation
  creation rollback.
* controlplane/dataplaneevents: Decorate logs with extra event details.
* controlplane/diagnostics: Asymmetrically encrypt bundles.
* controlplane/diagnostics: Collect FSM state.
* controlplane/diagnostics: Support single node bundle collection.
* controlplane/diagnosticutil: Decorate log entries with well-known field
  corresponding to node id/name.
* controlplane/diagnosticutil: Parallelise unpacking of disjoint data.
* controlplane/diagnosticutil: Unpack gathered NFS config data.
* controlplane/fsm: Perform state match check before version check.
* controlplane/k8s: Use secret store.
* controlplane/log: Fix race condition writing logs.
* controlplane/log: Handle originator timestamps from dataplane logs.
* controlplane/meta: Error checking code uses Go 1.13 error features.
* controlplane/rpc: Make CP gRPC calls to the DP configuration endpoints
  idempotent.
* controlplane/sentry: Prevent some unnecessary alerts.
* controlplane/slog: Clean up error logging in RPC provision stack.
* controlplane/states: Add the "from" state as a log field for state transition
  msgs.
* controlplane/store/etcd: Decorate lock logs with associated ID fields.
* controlplane/ui: Warn user that updating labels action will be reverted.
* controlplane/vendor: Bump service repository.
* controlplane/volume: Encryption support in kubernetes.

* dataplane/fs: Don't return from PresentationCreate RPC until the device is
  fully created.
* dataplane/fs: Each LUN should have it's own HBA.
* dataplane/fs: Improve device ready check.
* dataplane/internals: Improve DP stats implementation.
* dataplane/internals: Major director refactor.
* dataplane/log: Logs should output originating timestamps.
* dataplane/log: Move to log3 API exclusively.
* dataplane/log: Remove log2.
* dataplane/log: Set log_level and log_filter via the supctl tool.
* dataplane/rdb: Handle unaligned I/O in RdbPlugin.
* dataplane/rdb: Implement low-level "delete block" functionality.
* dataplane/rdb: rocksdb Get() should use an iterator.
* dataplane/story: Support for block unmapping.
* dataplane/story: Add backuptool binary to export volume data.
* dataplane/story: Volume encryption-at-rest.
* dataplane/sync: Add retries for failed sync IOs.
* dataplane/sync: VolumeHash performance improvements.
* dataplane/sys: Find and check OS pids.max on startup.

* k8s/api-manager: Don't attempt service creation if the owning PVC doesn't
  exist.
* k8s/api-manager: Compare SC and PVC creation time during label sync.
* k8s/api-manager: Add action to ensure modules tidy & vendored.
* k8s/api-manager: Add defaults from StorageClass.
* k8s/api-manager: Add fencing controller.
* k8s/api-manager: Add flag and support for cert validity.
* k8s/api-manager: Add flags to disable label sync controllers.
* k8s/api-manager: Add namespace delete controller.
* k8s/api-manager: Add node delete controller.
* k8s/api-manager: Add OpenTelemetry tracing with Jaeger backend.
* k8s/api-manager: Add PVC label sync controller.
* k8s/api-manager: Add PVC mutating controller.
* k8s/api-manager: Add support for failure-mode label.
* k8s/api-manager: Add support for volume encryption.
* k8s/api-manager: Allow multiple mutators.
* k8s/api-manager: Build and tests should use vendored deps.
* k8s/api-manager: Bump controller-runtime to v0.6.4.
* k8s/api-manager: Encrypt only provisioned PVCs.
* k8s/api-manager: Fix tracing example.
* k8s/api-manager: Introduce StorageClass to PVC annotation mutator.
* k8s/api-manager: Log API reason.
* k8s/api-manager: Migrate namespace delete to operator toolkit.
* k8s/api-manager: Migrate node delete to operator toolkit.
* k8s/api-manager: Migrate to kubebuilder v3.
* k8s/api-manager: Node label sync.
* k8s/api-manager: Node label update must include current reserved labels.
* k8s/api-manager: Pass context to API consistently.
* k8s/api-manager: Rename leader election config map.
* k8s/api-manager: RFC 3339 and flags to configure level & format.
* k8s/api-manager: Run shared volume controller with manager.
* k8s/api-manager: Set initial sync delay.
* k8s/api-manager: Set Pod scheduler.
* k8s/api-manager: Standardise on ObjectKeys for all API function signatures.
* k8s/api-manager: Ondat API interface and mocks.
* k8s/api-manager: Update dependencies and go version 1.16.
* k8s/api-manager: Update to new external object sync.
* k8s/api-manager: Use composite client in admission controllers.
* k8s/api-manager: Use Object interface.

* k8s/cluster-operator: Changes to the StorageOSCluster CR get applied to Ondat.
* k8s/cluster-operator: Increase provisioner timeout from 15 to 30s.
* k8s/cluster-operator: Reduce CSI provisioner worker pool.
* k8s/cluster-operator: Set priority class for helper pods.
* k8s/cluster-operator: Add pod anti-affinity to api-manager.
* k8s/cluster-operator: Add pvc mutator config.
* k8s/cluster-operator: Add rbac for api-manager fencing.
* k8s/cluster-operator: Add RBAC for encryption key management.
* k8s/cluster-operator: Add RBAC needed for csi-resizer v1.0.0.
* k8s/cluster-operator: Add webhook resource migration.
* k8s/cluster-operator: Add workflow to push image to RedHat registry.
* k8s/cluster-operator: Bump csi-provisioner to v2.1.1.
* k8s/cluster-operator: Call APIManagerWebhookServiceTest test.
* k8s/cluster-operator: Delete CSI expand secret when cluster is deleted.
* k8s/cluster-operator: Docker login to avoid toomanyrequests error.
* k8s/cluster-operator: Move pod scheduler webhook to api-manager.
* k8s/cluster-operator: RBAC to allow sync functions move to api-manager.
* k8s/cluster-operator: Remove pool from StorageClass, not used in v2.
* k8s/cluster-operator: Remove some other v1.14 specific logic.
* k8s/cluster-operator: Set the default container for kubectl logs.
* k8s/cluster-operator: Update code owners.
* k8s/cluster-operator: Update CSI sidecar images.
* k8s/cluster-operator: Validate minimum Kubernetes version.

## v2.3.4 - Released 2021-03-24

* controlplane/build: Use Sentry prod-url for release branches (CP-4600).
* controlplane/csi: Improve CSI handler timeout (CP-4585).
* controlplane/dataplane: UUID mapping cleanup on failed volume creation (CP-4588).
* controlplane/slog: Improve RPC error logging (CP-4616).
* dataplane: Allocate fewer aio contexts per volume (DP-305)
* dataplane: Defer fallocate(2) until first write (DP-312).
* dataplane: Don't fail replica sync if inter-node connection establishment is slow (DP-319, DP-280).
* dataplane: Improve logging around gRPC context cancellations (DP-315).
* dataplane: Improve rollback for failed volume creation (DP-308).
* dataplane: New support tool to cleanup orphaned volume storage (DP-307).
* dataplane: supctl can reap named volumes (DP-309).
* k8s: API token reset failures should trigger re-authentication directly (#38).
* k8s: Increase lint timeout to reduce CI errors (#305).
* k8s: Remove PriorityClass from helper pods (#312).
* k8s: Toleration defaults for helper pods (#311).
* k8s: Use ubi-minimal base image directly (#307).

## v2.3.3 - Released 2021-02-12

* Support CSI ListVolumes() API, addressing volume attach problems seen by some
  customers.
* Quality-of-life fixes.

### New

* operator: Use CSI attacher v3 for k8s 1.17+.
* controlplane/csi: ListVolumes support.

### Fixed

* api-manager: Reset API after token refresh error.
* operator: Set scheduler when PVCs use default StorageClass.
* operator: Update base container image.
* controlplane/volumerpc: "Got unknown replica state 0" discards results.
* controlplane/healthcheck: Combined sources fires callback in initialisation.
* controlplane/fsm: Perform state match check before version check.

## v2.3.2 - Released 2020-11-25

### Fixed

* controlplane/rejoin: Failure to delete data causes re-advertise loop.
* controlplane/rejoin: Handle timeout waiting for progress report.
* dataplane/log: Change buffering of `symmetra` output to prevent stalls.

## v2.3.1 - Released 2020-11-16

* Allows access to `ReadWriteMany` shared volumes when running containers as a
non-root user.

### Fixed

* nfs: root squash to uid=0 is now configured on all shared volumes.

## v2.3.0 - Released 2020-10-31

This release adds production-grade shared file support to v2, previously a
technology preview in v1.

### Breaking

* The `v2.3.0` operator is no longer able to run Ondat v1.

### New

* Adds support for `ReadWriteMany` shared volumes.  See
  [ReadWriteMany](/docs/concepts/rwx).
* Adds `api-manager` deployment to support shared volumes.  See [the api
  manager](https://github.com/storageos/api-manager) GitHub repository for more
  information.
* Kubernetes 1.19 support.

### Improved

* dataplane: Reduce replication thread usage by having the replication processes
  share the main thread pool.  This helps ensure that there isn't a spike in
  thread usage when a node recovers and begins re-syncing its volumes.  This is
  particularly relevant on CRIO-based orchestrators such as Openshift where the
  default maximum allowed PID limit (which also governs the thread limit) is
  low.
* dataplane: Detect and log the effective maximum PID limit on startup.
* dataplane: Internal device presentation mappings are now ephemeral and are not
  persisted across reboots.
* dataplane: Disabled default verbose logging for fdatasync/flushWAL timers.
* dataplane: Log both volume inode and UUID in replication error messages for
  easier correlation.
* dataplane: On startup, ensure any remnant devices that may have been left
  after an unclean shutdown have been properly cleared.
* dataplane: Signal when all startup tasks complete.  This ensures no IO can be
  initiated before this time.
* ha: Implement a backoff when attempting to repoint an attached volume after
  the master has failed.
* ha: Replicas can now rejoin after an asymmetric partition. This can occur when
  the master has not lost communication to the replica, but the replica can't
  communicate with the master.  Previously the replica would not be able to
  rejoin until the master determined it had failed.
* ha: A master that was partitioned can now re-join to the new master as a
  replica.
* api: node label changes update target node prior to committing new state.
* api: Validation errors now include more information on the failure and how to
  resolve.
* csi: Volume resize error messages (e.g. capacity exceeded) now passed through
  in CSI response.
* csi: Volume attachment is now verified prior to mount for more instructive
  error message.
* csi: Returns `RESOURCE EXHAUSTED` error when attempting to exceed maximum of
  250 Ondat volume attachments per node.
* diagnostics: Multiple improvements to bundle collection and collected data.
* ui: Allow collection of partial diagnostics bundles.
* ui: Tolerate clock skew when authenticating via the UI.
* licensing: Read-through cache added.  Licence updates will take up to 60s to
  propagate to all nodes.
* cli: Set replicas output formatting.
* init: Checks the effective maximum PID limit and warns if less than the
  Ondat recommended PID limit (32,768).  CRIO-based distributions such as
  Openshift have a much lower default value (1024).  Consult
  [prerequisites](/docs/prerequisites/pidlimits) for more
  information.

### Fixed

* dataplane: Fixes `transport endpoint is not connected` on startup after an
  unclean shutdown.
* csi: Volume unmount requests now succeed when the mountpoint has
  already been removed by the orchestrator.
* csi: Volume detach requests now succeed when the volume has already been
  deleted.  Previously the volume would be stuck in `Terminating` status.

## v2.2.0 - Released 2020-08-18

This release focuses on performance. We analysed existing performance
characteristics across a variety of real-world use cases and ended up with
improvements across the board. Of particular note:

* Sequential reads have improved by up to 130%
* Sequential writes have improved by up to 737%
* Random reads have improved by up to 45%
* Random writes have improved by up to 135%
* I/O for large block sizes (128K) has improved by up to 353%

We are extremely proud of our performance and we love to talk about it. Have a
look at the [Benchmarking](/docs/introduction/self-eval#Benchmarking) section of the
self-evaluation guide and consider sharing
your results. Our PRE engineers are available to discuss in our [slack
channel](https://storageos.slack.com).

### New

* Data engine revamp focused on provable consistency and performance. Key
  characteristics:

  * Metadata is stored in an optimised index, lowering I/O latency and improving
    performance for all workloads.
  * Large block reads/writes are now be handled in a single operation.
    Applications like Kafka will go much faster.

* On-disk compression is now disabled by default as in most scenarios this
  offers better performance. To enable on-disk compression for a specific
  workload, see [compression](/docs/concepts/compression).

### Improved

* dataplane: The number of I/O threads are now determined by the number of
  processing cores available.  This improves scalability and performance on
  larger servers.
* ha: Improve partition tolerance behaviour when a volume master that has lost
  its connection to etcd rejoins.
* ha: Allow replicas in unhealthy states to be remediated and re-used while
  maintaining partition tolerance.
* ha: When a master fails and the new master is not yet available, introduce a
  back-off to the redirection logic to avoid spamming the logs with connection
  failure errors.
* ha: Ignore health advertisements for local node. Local nodes are handled
  directly.
* node delete: Only refuse to delete a node if the node health can be
  authoritatively verified to be in use.
* api: Increase HTTP server write timeout.
* cli/ui: Allow partial diagnostic bundle downloads.
* ui: Namespace dropdown can now be scrolled.
* ui: Add "Job title" to UI licence form.
* logging: Log version at startup at INFO level.
* logging: Lower verbosity of SCSI warnings that do not apply to Ondat.
* diagnostics: Include logs that have been rotated.
* diagnostics: Bundle collection across providers is now done in parallel.
* build: Update base image to RHEL 8.2.
* operator: Removed DB migration utility required for v1.3 -> v1.4 upgrades.
* operator: Automatically refreshes Ondat API token without failing
  requests when the token expires.
* operator: Updated CSI attacher and provisioner to latest upstream.
* operator: Remove `cluster.local` suffix on Pod scheduler service address.
  This allows the scheduler to work in clusters with custom DNS configuration.
* operator: Defaults are now set for most CSI configuration options in the
  StorageOSCluster custom resource.

### Fixed

* csi: When unmount request is received for a volume that has already been
  unmounted, return success.
* csi: Verify volume is attached on the node before mounting it.
* xfs: Support older RHEL kernels which have an XFS library that does not
  allow reflinks/dedupe.
* dataplane: Reserve 1GiB of capacity on the target disk to allow manual cleanup
  operations, rather than filling target disk to capacity.
* operator: In some cases `/var/lib/storageos` could fail to unmount cleanly
  after a restart. This resulted in multiple entries in `/proc/mounts`.

## v2.1.0 - Released 2020-06-26

### New

* csi: Volume expansion now supported in offline mode. To expand a volume, stop
  any workloads accessing the volume, then edit the PVC to increase the
  capacity. For more information, see our [Volume Resize](/docs/operations/resize) operations page and the [`CSI Volume
  Expansion`](https://kubernetes-csi.github.io/docs/volume-expansion.html)
  page.
* api: Volume configuration including replica count can now be updated while
  the volume is in use. Other updateable fields include labels and
  description.
* failover: Before determining that a node is offline and performing recovery
  operations, the I/O path is also verified. This provides more robust failure
  detection and ensures that nodes that are still responding to I/O do not get
  replaced. This I/O path verification is in addition to the gossip-based
  failure detection.
* operator: Default tolerations are now set for the Ondat node container.
  This helps ensure that the Ondat node container does not get evicted when
  the node is running low on resources.

### Improved

* api: Added checks to prevent deletion of a node with active volumes, or if it
  is the master of at least one volume. This helps prevent orphaned volumes.
* cli: Add an `--offline-delete` flag to allow removal of volumes whose master
  and replica nodes are offline. This allows cleanup of orphaned volumes.
* ui: Add an offline volume delete option.
* ui: Volumes can now be detached from the UI.
* cli: Labels are no longer truncated.
* api: When a new node is added to the cluster, its capacity is available to use
  immediately.

### Fixed

* ui: Favicon was missing.
* ui: Duplicate volumes could be shown on the node details page.
* operator: During uninstall a ClusterRoleBinding was not removed.

## v2.0.0 - Released 2020-05-05

### New

* operator: Ondat containers now run in the `kube-system` namespace by
  default to allow the `system-node-critical` priority class to be set. This
  instructs Kubernetes to start Ondat before application Pods, and to evict
  Ondat only after application Pods have finished. This setting was
  previously recommended in documentation; it is now the default.
* operator: Ondat CSI helper containers now run as privileged. This ensures
  that the CSI endpoint can be seen on systems with SELinux enabled.
* ui: replication progress for new or re-joining replicas is now displayed.
* ui: show warning for unlicensed clusters.
* cli: new commands:
  * licence management
  * get policy
  * create namespace
  * create policy
  * describe user
  * describe namespace
  * describe policy
  * delete user
  * delete namespace
  * delete policy
* licence: removed the default licence expiry date added for `v2.0.0-rc.1`.

### Improved

* dataplane: improved retry behaviour for network I/O.
* cli: "get volumes" for all namespaces should be done in parallel.
* cli: help text document config file
* ui: link node name and get to node details on the volume details page.
* ui: node details add available capacity spinner.
* ui: node list remove capacity values / address port.
* ui: node list show master/replica counts.
* ui: node list remove edit action.
* ui: format entity labels.
* ui: node details link volumes.
* ui: align buttons for licences.
* ui: k8s warning in "create volume" modal.
* ui: node list remove "API" from "API Address"
* ui: add some details about the Licence on the licence page.
* api: include valid for duration in login response.
* licence: restrict nodes which are unregistered after 24 hours.
* scheduler: return error for namespace/volume not found
* dataplane: start gRPC threads separately from rest of the supervisor.

### Fixed

<<<<<<< HEAD

* ui: centre licence types.
* ui: capacity in ui is per namespace.
* cli: fail gracefully if missing some output details (i.e. no node exists for ID).
=======

* ui: centre licence types.
* ui: capacity in ui is per namespace.
* cli: fail gracefully if missing some output details (i.e. no node exists for ID).

>>>>>>> main

## v2.0.0-rc.1 - Released 2020-03-31

Initial release of version 2.x. See [Ondat v2.0 Release
Blog](https://storageos.com/storageos-2-0-release-blog) for details.
