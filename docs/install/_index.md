---
title: "Introduction"
linkTitle: Introduction
weight: 1
---

## What is Ondat

![How Ondat fits in](/images/docs/concepts/ondat-layer.png)

So you run workloads, either in-house developed or using Consumer Off The Shelf (COTS) platforms. You also recognise that operationally, you want to run them on Kubernetes as my “cloud operating system” of choice. This gives you freedom to deploy and operate your workloads anywhere Kubernetes runs based on business criteria such as cost, locality, compliance needs and risk appetite.

You have been running stateless workloads in such a way for years, now your developers/suppliers have decided to move the application state (database/message queue/ flat files/ key-value store…) into your Kubernetes clusters as well. They are proposing to do this to reduce operational toil as they can leverage “Operators” to deliver domain specific knowledge in the running of these components.

State now matters in your Kubernetes cluster, but hang on, how do we deliver the same operational paradigm that we are used to for these stateful workloads?

**The answer is Ondat.**

In the first wave of Kubernetes adoption, the focus was on stateless workloads. These workloads did not care if a pod or node was killed. They can just move to another node in the cluster and restart with minimal fuss.
What happens when we suddenly have data and state, well the obvious answer is that you need network attached storage which can be re-pointed to react in the same way as we have come to expect as for our stateless workloads.

This is Ondat, delivering a data mesh using Kubernetes native constructs to power stateful applications. Ondat couples any storage to any Kubernetes cluster and, with the simple application of Kubernetes labels, also delivers advanced features such as:
Encryption at a per Kubernetes volume level, allowing for safe multi-tenant operations.
Topology aware placement of volumes to align with your availability zones and physical architecture to ensure your data compliance.
Replication of data at a Kubernetes Volume making sure that the data you need is protected to deliver the business resilience required.

Using Ondat, any storage on any node in your Kubernetes cluster can be delivered to the applications that need it anywhere in the cluster. Intelligent placement makes sure that your workload is always optimised, and by deploying the Ondat data mesh your Kubernetes platforms are responsive to your business applications with compute and storage able to grow independently as your workloads change.

This is Ondat, a data mesh to deliver the reality of stateful workloads to any Kubernetes platform, delivering the next generation of stateful workloads to your customers.