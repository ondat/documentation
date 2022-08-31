---
title: "Solution - Troubleshooting Ondat Daemonset `CrashLoopBackOff`  Pod States after Re-installing Ondat"
linkTitle: "Solution - Troubleshooting Ondat Daemonset `CrashLoopBackOff`  Pod States After Re-installing Ondat"
---

## Issue

You are experiencing `CrashLoopBackOff` states for Ondat daemonset pods >> `storageos-node-*` after conducting an Ondat re-installation on a cluster that was previously running Ondat.

```bash
# Get the status of Ondat daemonset pods.
kubectl get pods --namespace storageos

NAME                                   READY   STATUS             RESTARTS        AGE
storageos-node-6kjvg                   2/3     CrashLoopBackOff   7 (2m5s ago)    13m
storageos-node-7mxth                   2/3     CrashLoopBackOff   7 (106s ago)    13m
storageos-node-8vrl8                   2/3     CrashLoopBackOff   7 (117s ago)    13m
storageos-node-8zssp                   2/3     CrashLoopBackOff   7 (2m1s ago)    13m
storageos-node-qvf58                   2/3     CrashLoopBackOff   7 (2m13s ago)   13m
storageos-operator-6fdccfd899-g5hff    2/2     Running            0               14m
storageos-scheduler-7f7ddd896b-4ngb9   1/1     Running            0               13m
```

Upon further investigation into the logs of one of the Ondat daemonset pods that are in a `CrashLoopBackOff` state, there is an error message related to the `/var/lib/storageos/config.json` configuration file.

```bash
# Get the logs for one of the Ondat daemonset pods.
kubectl logs storageos-node-8zssp --namespace storageos

{"bin_build_date":"2022-08-08T15:55:20.630504657+00:00","bin_build_ref":"","bin_git_branch":"release/v2.8.2","bin_git_commit_hash":"396dcc6ea2c4a267a33f1204d2836e1aee6f24de","bin_version":"2.8.2","level":"info","msg":"starting StorageOS","time":"2022-08-28T15:18:57.006231412Z"}
{"env_advertise_address":"10.106.0.3","env_api_bind_address":"","env_api_tls_ca":"","env_bind_address":"","env_bootstrap_namespace":"","env_bootstrap_username":"storageos","env_csi_endpoint":"unix:///var/lib/kubelet/plugins_registry/storageos/csi.sock","env_csi_version":"v1","env_dataplane_daemon_dir":"","env_dataplane_dir":"","env_device_dir":"","env_dial_timeout":"","env_disable_crash_reporting":"false","env_disable_telemetry":"false","env_disable_version_check":"false","env_encryption_enabled":"","env_etcd_endpoints":"storageos-etcd.storageos-etcd:2379","env_etcd_namespace":"","env_etcd_tls_client_ca":"/run/storageos/pki/etcd-client-ca.crt","env_etcd_tls_client_cert":"/run/storageos/pki/etcd-client.crt","env_etcd_tls_client_key":"/run/storageos/pki/etcd-client.key","env_etcd_username":"","env_gossip_advertise_address":"","env_gossip_bind_address":"","env_health_grace_period":"","env_health_probe_interval":"","env_health_probe_timeout":"","env_health_tcp_timeout":"","env_hostname":"default-7f882","env_internal_api_advertise_address":"","env_internal_api_bind_address":"","env_internal_tls_ca_cert":"","env_internal_tls_node_cert":"","env_internal_tls_node_key":"","env_io_advertise_address":"","env_io_bind_address":"","env_jaeger_endpoint":"","env_jaeger_service_name":"","env_k8s_config_path":"","env_k8s_distribution":"","env_k8s_enable_scheduler_extender":"true","env_k8s_namespace":"default","env_log_file":"","env_log_format":"json","env_log_level":"info","env_log_size_limit":"","env_nfs_advertise_ip":"","env_nfs_binary_path":"","env_nfs_bind_ip":"","env_nfs_bind_port_base":"","env_nfs_log_size_limit":"","env_node_capacity_interval":"","env_node_lock_ttl":"","env_placement_api_bind_address":"127.0.0.1:5712","env_placement_log_level":"info","env_placement_service_address":"127.0.0.1:5712","env_placement_service_binary_dir":"","env_placement_service_binary_name":"placement","env_prometheus_exporter_bind_address":"","env_prometheus_exporter_username":"","env_prometheus_tls_ca":"","env_root_dir":"","env_socket_dir":"","env_supervisor_advertise_address":"","env_supervisor_bind_address":"","env_volume_lock_ttl":"","level":"info","msg":"environment variables at startup","time":"2022-08-28T15:18:57.006601003Z"}
{"level":"info","msg":"ETCD connection established at: [storageos-etcd.storageos-etcd:2379]","time":"2022-08-28T15:18:57.056503227Z"}
{"level":"info","msg":"local node StorageOS ID: 33c6c45a-5109-4092-bd5e-0e76ade7fd6e","time":"2022-08-28T15:18:57.062314134Z"}
{"level":"info","msg":"local node Hostname is: default-7f882","time":"2022-08-28T15:18:57.062367342Z"}
{"level":"info","msg":"joining cluster: eb5546d9-7332-4b73-935a-5d2373b93bf2","time":"2022-08-28T15:18:57.690018218Z"}
{"level":"info","msg":"node lock refresh interval: 30s","time":"2022-08-28T15:18:57.690187309Z"}
{"error":"node \"33c6c45a-5109-4092-bd5e-0e76ade7fd6e\" was previously a member of cluster id \"26cb5845-93c9-489d-bb80-e4a31791989f\", tried to join another cluster (\"eb5546d9-7332-4b73-935a-5d2373b93bf2\") - aborting startup. To delete all data on the node and join the new cluster, remove the \"/var/lib/storageos/config.json\" directory. To recover this node data, please contact support.","level":"error","msg":"failed to initialise local node","time":"2022-08-28T15:18:57.704875437Z"}
{"level":"info","msg":"shutting down","time":"2022-08-28T15:18:57.704982197Z"}

# Get the logs for one of the Ondat daemonset pods and use jq to clean up the formatting of the logs.
kubectl logs storageos-node-8zssp --namespace storageos | jq

# truncated log output...
{
  "level": "info",
  "msg": "ETCD connection established at: [storageos-etcd.storageos-etcd:2379]",
  "time": "2022-08-28T15:18:57.056503227Z"
}
{
  "level": "info",
  "msg": "local node StorageOS ID: 33c6c45a-5109-4092-bd5e-0e76ade7fd6e",
  "time": "2022-08-28T15:18:57.062314134Z"
}
{
  "level": "info",
  "msg": "local node Hostname is: default-7f882",
  "time": "2022-08-28T15:18:57.062367342Z"
}
{
  "level": "info",
  "msg": "joining cluster: eb5546d9-7332-4b73-935a-5d2373b93bf2",
  "time": "2022-08-28T15:18:57.690018218Z"
}
{
  "level": "info",
  "msg": "node lock refresh interval: 30s",
  "time": "2022-08-28T15:18:57.690187309Z"
}
{
  "error": "node \"33c6c45a-5109-4092-bd5e-0e76ade7fd6e\" was previously a member of cluster id \"26cb5845-93c9-489d-bb80-e4a31791989f\", tried to join another cluster (\"eb5546d9-7332-4b73-935a-5d2373b93bf2\") - aborting startup. To delete all data on the node and join the new cluster, remove the \"/var/lib/storageos/config.json\" directory. To recover this node data, please contact support.",
  "level": "error",
  "msg": "failed to initialise local node",
  "time": "2022-08-28T15:18:57.704875437Z"
}
{
  "level": "info",
  "msg": "shutting down",
  "time": "2022-08-28T15:18:57.704982197Z"
}

# Drill down into the Ondat daemonset logs further and search for the "error" message that is reported.
kubectl logs storageos-node-8zssp --namespace storageos | jq | grep "error"

  "error": "node \"33c6c45a-5109-4092-bd5e-0e76ade7fd6e\" was previously a member of cluster id \"26cb5845-93c9-489d-bb80-e4a31791989f\", tried to join another cluster (\"eb5546d9-7332-4b73-935a-5d2373b93bf2\") - aborting startup. To delete all data on the node and join the new cluster, remove the \"/var/lib/storageos/config.json\" directory. To recover this node data, please contact support.",
  "level": "error",
```

## Root Cause

The root cause of this is due to the existing Ondat configuration file that is stored at the following location >> `var/lib/storageos/config.json` on each node where Ondat daemonset pods runs. The configuration file is not removed to allow cluster administrators and end users to be able to successfully recover incase the uninstall was unintentional.

- For more information on uninstalling Ondat, review the [How To Uninstall Ondat](/docs/operations/uninstall/) operations page.

## Resolution

1. If you have already re-installed Ondat, follow the [How To Uninstall Ondat](/docs/operations/uninstall/) operations page again to remove Ondat.
2. Once Ondat has been removed, run the following command below against the cluster - the command will execute a bash script that deploys a daemonset which will remove the Ondat data directory >> `/var/lib/storageos/` - permanently deleting data and metadata related to Ondat on the nodes.

> ⚠️ WARNING - This step is irreversible and will permanently remove any existing data in >> `/var/lib/storageos/`. Ensure that you have backed up your data before executing this step. Users can also review the contents of the bash script which is available in the [Ondat Use Case repository](https://github.com/ondat/use-cases/blob/main/scripts/permanently-delete-storageos-data.sh) publicly available on GitHub to verify before executing.

```bash
# Permanetly delete the contents located in "/var/lib/storageos/".
curl --silent https://raw.githubusercontent.com/ondat/use-cases/main/scripts/permanently-delete-storageos-data.sh | bash
```

3. Once the script has finished executing, you can [re-install Ondat](/docs/install/) again into your cluster without experiencing `CrashLoopBackOff` states for Ondat daemonset pods - caused by an old `var/lib/storageos/config.json` configuration file.
