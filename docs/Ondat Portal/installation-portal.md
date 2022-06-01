---
title: "Ondat SaaS Platform Installation Guide"
linkTitle: "Ondat Portal Installation Guide"
weight: 1
---

## Overview

This guide will demonstrate how to install the [Ondat SaaS Platform](https://portal.ondat.io/).

## Prerequisite

> ⚠️ Make sure the kubectl storageos plugin is installed. Follow the [install guide for kubectl storageos](https://docs.ondat.io/docs/reference/kubectl-plugin/).

> ⚠️ Make sure to add an [Ondat licence](/docs/operations/licensing/) after installing.

> ⚠️ You must enable port 8883 for egress in your ACLs if a VPC is used.

## Procedure

### Step 1: Creating Credentials for Your Cluster

1. Open [Ondat Portal](https://portal.ondat.io/dashboard).
2. Log into your account using your credentials.
3. In the main navigation, open the __Cluster__ tab.
4. On the __Cluster__ screen, click the __Add Cluster__ button.
5. Enter a name for the cluster and choose the __Cluster Location__ using the dropdown
6. Click __Create Cluster__

### Step 2a: Option A - Installing Ondat Portal Manager when Ondat was not installed beforehand

1. Copy the first cli command displayed on the modal, __this will be the only time it will be visible__.
2. Execute the cli command on your machine

### Step 2b: Option B - Installing Ondat Portal Manager when Ondat has already been installed

1. Copy the second cli command displayed on the modal, __this will be the only time it will be visible__.
2. Execute the cli command on your machine
