---
title: "Cluster Operator upgrade"
linkTitle: Contributing to the documentation
weight: 40
---

## Upgrade Ondat operator from yaml manifest

Upgrade the Ondat operator using the following yaml manifest.

```
kubectl apply -f https://github.com/storageos/cluster-operator/releases/download/v2.4.4/storageos-operator.yaml
```

> 💡 When you run the above command Ondat Operator resources will be updated.
> Since, the Update Strategy of the Ondat Operator Deployment is set to
> rolling update, a new Ondat Operator Pod will be created. Only when
> the new Pod enters the Running Phase will the old Pod be deleted.
> Your Ondat Cluster will not be affected while the Ondat
> Operator is upgrading.

## Upgrade Ondat Operator using Helm

If you have installed the Ondat Operator using the [Helm Chart](https://github.com/storageos/charts/tree/master/stable/storageos-operator#installing-the-chart), then you can upgrade the operator using the following commands.

```
$ helm list

NAME            REVISION        STATUS          CHART                           APP VERSION     NAMESPACE   
storageos-v1   4               DEPLOYED        storageos-operator-0.2.11       1.3.0           storageos-operator
```

```
helm repo update
helm upgrade $NAME storageos/storageos-operator
```

> 💡 When you run the above command Ondat Operator resources will be updated.
> Since, the Update Strategy of the Ondat Operator Deployment is set to
> rolling update, a new Ondat Operator Pod will be created. Only when
> the new Pod enters the Running Phase will the old Pod be deleted.
> Your Ondat Cluster will not be affected while the Ondat
> Operator is upgrading.
