---
title: "Ondat SaaS Platform Installation Guide"
linkTitle: "Ondat SaaS Platform Installation Guide"
weight: 1
---

## Overview

This guide will demonstrate how to install the [Ondat SaaS Platform](https://portal.ondat.io/).

## Prerequisite

> ⚠️ Make sure the kubectl storageos plugin is installed. Follow the [install guide for kubectl storageos](https://docs.ondat.io/docs/reference/kubectl-plugin/).

> ⚠️ Make sure to add an [Ondat licence](/docs/operations/licensing/) after installing. You can request a licence via the [Ondat SaaS Platform](https://portal.ondat.io/).

> ⚠️ You must enable port 443 for egress in your ACLs if a VPC is used.

## Procedure

### Step 1: Set up your cluster

1. Open [Ondat SaaS Platform](https://portal.ondat.io/)
1. Log into your account using your credentials
1. In the main navigation, open the __Cluster__ tab
1. On the __Cluster__ screen, click the __Add Cluster__ button
1. Enter a name for the cluster and choose the __Cluster Location__ using the radio buttons
1. Click __Add Cluster__

### Step 2: Connect Cluster to the Ondat SaaS Platform

> Note: The CLI command will only be displayed __once__
> Note: Latest GA version of Ondat will be installed onto your cluster

1. Make sure you follow all the prerequisites displayed on the screen. You can find more information [here](/docs/prerequisites/) for the prerequisites of using Ondat.
1. Copy the cli command displayed on the screen
1. Execute the cli command on your machine
