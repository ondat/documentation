---
title: "Jenkins"
linkTitle: Jenkins
---

![jenkinslog](/images/docs/explore/jenkins.png)

This example shows an example of how to deploy Jenkins on Kubernetes with a
Ondat persistent volume being mounted on `/var/jenkins_home`. Deploying
Jenkins using Ondat offers multiple benefits. Firstly Jenkins can spin up
multiple build pods at once to allow concurrent builds of different projects.
Secondly Jenkins configuration is on a PersistentVolume so even if the Jenkins
pod is rescheduled the configuration will persist.

Using Ondat [volume replicas](/docs/concepts/replication) allows for
failure of nodes holding the PersistentVolume without interrupting Jenkins.
Lastly by enabling Ondat [fencing](/docs/concepts/fencing) Jenkins time to
recover, in case of node failures, is greatly reduced.

Before you start, ensure you have Ondat installed and ready on a Kubernetes
cluster. [See our guide on how to install Ondat on Kubernetes for more information](/docs/install/kubernetes)

## Deploying Jenkins on Kubernetes

1. You can find the latest files in the Ondat example deployment
   repository.

   ```bash
   git clone https://github.com/storageos/use-cases.git storageos-usecases
   cd storageos-usecases
   kubectl create -f ./jenkins
   ```

1. Confirm that Jenkins is up and running

   ```bash
   $ kubectl get pods -w -l app=jenkins
      NAME        READY    STATUS    RESTARTS    AGE
      jenkins-0   1/1      Running    0          1m
   ```

1. Connect to the Jenkins UI through the Jenkins service.

   You can do this by port forwarding the Jenkins Kubernetes service to your
   localhost and accessing the UI via your browser. Alternatively if you have
   network access to your Kubernetes nodes then you can create a NodePort service
   and access Jenkins like that. A NodePort service has been left in
   `10-service.yaml` commented out.

   To port-foward the Jenkins service use the following command.

   ```bash
   kubectl port-foward svc/jenkins 8080
   ```

   To login to the Jenkins UI use the credentials specified in
   [`07-config.yaml`](https://github.com/storageos/use-cases/blob/master/jenkins/07-config.yaml),
   unless these have been changed from the defaults the username/password is
   admin/password.

1. Create a Jenkins job.

   Once you are logged into the UI you can create a job that will be farmed out to
   a Kubernetes plugin build agent. Click New Item, enter a name for the project
   and select Freestyle project. Next add an `Execute shell` build step. As a
   proof of concept you can use the bash below to have the pod execute a sleep.

   ```bash
   #!/bin/bash
   sleep 1000
   ```

   Save the project and select Schedule a build of your project. You can watch for
   the appearance of a build pod using `kubectl get pods -l jenkins=agent -w`.
   Once the pod is created you should see the Build Executor status in the Jenkins
   UI display the pod.

   To see multiple projects being built at once create another project and try
   scheduling a build of both projects at the same time.
