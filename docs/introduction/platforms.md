---
title: "Supported Platforms and Orchestrators"
linkTitle: Supported Platforms
weight: 40
description: >
    Ondat runs on a variety of platforms and orchestrators. The following
    sections detail these, and any known platform specific limitations.
---

## OS

- Linux X86_64
- Kernels satisfying our module [prerequisites](/docs/prerequisites/systemconfiguration)
- 3.x kernels have a limitation of 256 active volumes per node
- 4.x kernels have a limitation of 4096 active volumes per node
- We are distribution agnostic as long as our prerequisites are met

## Orchestrators

- Kubernetes 1.18 to 1.22
- OpenShift 4.0+

