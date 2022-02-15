---
title: "Ondat Portal Installation Guide"
linkTitle: "Ondat Portal Installation Guide"
weight: 10
---

# Creating Credentials for Your Cluster

1. Open [Ondat Portal](https://portal.ondat.io/dashboard).
2. Log into your account using your account's credentials.
3. On the lower left-hand side of the screen, open the __Organization__ tab.
4. Open the __API Tokens__ tab and select __Create API Token__.
5. Enter a name for the API token. Note that, if there is another API Token with the same description that token will be replaced by this one.
6. Copy all information on the page, this will be the only time it will be visible. Make note of the API secret.

# Installing Ondat on Your Cluster Using the Ondat Portal Manager

Execute this command if you are configuring a cluster without having installed Ondat beforehand. You can use the credentials you have just created to execute the command below:

```bash
kubectl storageos install 
        --include-etcd=true 
        --stos-version=develop 
        --enable-portal-manager 
        --portal-client-id=<clientid> 
        --portal-secret=<secret> 
        --portal-api-url=<api-url> 
        --portal-tenant-id=<tenantId>
```

# Installing Ondat Portal Manager

Execute this command if you are configuring a cluster in which Ondat has already been installed.

```bash
kubectl storageos install-portal 
        --portal-client-id=<clientid> 
        --portal-secret=<secret> 
        --portal-api-url=<api-url> 
        --portal-tenant-id=<tenantId>
```
