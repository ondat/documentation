---
title: Support
linkTitle: Support
weight: 800
description: >
  How to ask for Ondat support.
---

When you need support, raise a ticket via our [Help Desk
portal](https://support.ondat.io/). 

It is important to select the priority of your ticket in accordance with the severity. This helps us to route and prioritise your ticket accordingly.

Responses to tickets will be cc'd via email.

For personal support and general enquiries, join our [public Slack channel](https://slack.storageos.com).

## Information to include in tickets

To help us provide effective support, we request that you provide as much information as possible when contacting us. The list below is a suggested
starting point. Additionally, include anything specific, such as log entries, that may help us debug your issue.

### Platform

* Cloud provider/Bare metal
* OS distribution and version
* Kernel version

### Ondat

* Version of Ondat
* `storageos get nodes`
* `storageos get volumes`
* `storageos describe volume VOL_ID` # in case of issues with a specific volume

### Orchestrator related (Kubernetes, OpenShift, etc)

* Version and installation method
* Managed or self managed?
* `kubectl -n storageos get pod`
* `kubectl -n storageos logs -lapp=storageos -c storageos`
* `kubectl -n storageos get storageclass`
* Specific for your namespaces: `kubectl describe pvc PVC_NAME`
* Specific for your namespaces: `kubectl describe pod POD_NAME`

### Environment Changes

* Details of any recent changes to your environment such as planned
  maintenance, node reboots, network failures, etcd outage, etc.. This can
  help speed up ticket triage and resolution considerably

### Ondat Support Bundle

Ondat provides the ability to generate a support bundle that aggregates cluster information. See [Support Bundle](/docs/reference/bundles/support_bundle) for a list of what is included.

Ondat engineers might ask for a support bundle to be generated during support cases.

The information in the bundle is used only for support purposes, and will be removed once it is no longer needed. If the information is sensitive and can't be given to Ondat, make sure that the support engineers have as much information about your environment as possible.

Refer to the [Support Bundle](/docs/reference/bundles/support_bundle) documentation page for details of how to generate a bundle.
