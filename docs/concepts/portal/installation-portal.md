---
title: "Ondat Portal Installation Guide"
linkTitle: "Ondat Portal Installation Guide"
---


# Setting Up a Local Cluster 

The following guide will take you through the process of setting up a cluster on your machine. If you are using an Apple M1 machine you need to run kind inside an amd64 VM hosted on a Cloud Service of your choice. Local emulation will not work on a machine using Apple M1. 

## Prerequisites

* You have set up your cluster using the following config file <cloud_init.yml>

* You have installed [multipass](https://multipass.run)
  
## Procedure

1. Open the directory where you have saved <cloud-init.yml>.
2. Create the `multipass` VM 
`multipass launch --name devk8s --mem 6G --cpus 2 --disk 30G --cloud-init ./k8s-cloud-init.yml -vvvv`
3. Log into the VM  
`multipass shell devk8s`
4. Create a local cluster using kind. You can find the latest `---image` tags on [Docker Hub](https://hub.docker.com/r/storageos/kind-node/tags)
`kind create cluster --image storageos/kind-node:v1.22.3 --name portal-dev`

# Creating Credentials foy Your Cluster

1. Open [Ondat Portal](https://portal.ondat.io/dashboard).
2. Log into your account using your account's credentials.
3. On the lower left-hand side of the screen, open the __Organization__ tab. 
4. Open the __API Tokens__ tab and select __Create API Token__.
5. Enter a name for the API token. Note that, if there is another API Token with the same description that token will be replaced by this one.
6. Copy all information on the page, this will be the only time it will be visible. Make note of the API secret. 

# Installing Ondat on Your Cluster Using the Ondat Portal Manager

Execute this command if you are configuring a cluster without having installed Ondat beforehand.
`kubectl storageos install --include-etcd=true --stos-version=develop --enable-portal-manager --portal-client-id=<clientid> --portal-secret=<secret> --portal-api-url=<api-url> --portal-tenant-id=<tenantId>`


# Installing Ondat Portal Manager 

Execute this command if you are configuring a cluster in which Ondat has already been installed.
`kubectl storageos install-portal --portal-client-id=<clientid> --portal-secret=<secret> --portal-api-url=<api-url> --portal-tenant-id=<tenantId>`





