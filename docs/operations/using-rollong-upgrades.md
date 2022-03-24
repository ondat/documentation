---
linkTitle: Using Rolling Upgrades Feature 
---

# Enabling Orchestrator's Rolling Upgrades 

To prevent your persistent storage volumes from becoming unhealthy during orchestrator update you need to enable rolling upgrades. Note, that if your volume doesn't have any replicas the rolling upgrades will be disabled by default. 

# Procedure

Enable both node manager and the upgrade guard by adding the following to the StorageOSCluster spec: 

```
 nodeManagerFeatures:
   upgradeGuard: ""
```

>You can also use this one-liner to do that:
` kubectl get storageoscluster -n storageos storageoscluster -o yaml | sed -e 's|^spec:$|spec:\n  nodeManagerFeatures:\n    upgradeGuard: ""|' | kubectl apply -f - `