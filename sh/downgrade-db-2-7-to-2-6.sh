#!/bin/bash

set -euo pipefail

CLI_TOOL=kubectl
#CLI_TOOL=oc
NAMESPACE=kube-system
DS_NAME=storageos-downgrade-database

echo "Downgrading Ondat dataplane database from v2.7.0+ to v2.6.0...."

# In order to create a workload that is functionally both a DaemonSet and a
# Job, the database downgrade is run as an init container.
# So, when the pod enters running it has completed.
$CLI_TOOL -n $NAMESPACE create -f-<<END
kind: DaemonSet
apiVersion: apps/v1
metadata:
  name: $DS_NAME
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: $DS_NAME
  template:
    metadata:
      name: $DS_NAME
      labels:
        app: $DS_NAME
    spec:
      serviceAccountName: daemon-set-controller
      initContainers:
      - name: downgrade-database
        image: soegarots/node:v2-release-v2.7.0-27
        imagePullPolicy: IfNotPresent
        command: ["db_downgrade_v4v3"]
        securityContext:
          allowPrivilegeEscalation: true
          capabilities:
            add:
            - SYS_ADMIN
          privileged: true
        volumeMounts:
        - mountPath: /var/lib/storageos
          mountPropagation: Bidirectional
          name: state
      containers:
      - name: sleep-once-complete
        command: ["/bin/sh"]
        args: ["-c", "while true; echo 'database downgrade container completed, sleeping indefinietly'; do sleep 3600; done"]
        image: busybox
        imagePullPolicy: IfNotPresent
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      volumes:
      - hostPath:
          path: /var/lib/storageos
          type: ""
        name: state
END

# When the number of Ready pods has matched the number of Desired, all init
# containers have finished.
# We also check that number is not 0 to avoid spurious results when starting.
echo "DaemonSet $DS_NAME created, watching until complete"

sleep 20

deleted=false
while ! $deleted; do
  sleep 2
  ready=$($CLI_TOOL get ds $DS_NAME -n $NAMESPACE -o jsonpath='{.status.numberReady}')
  desired=$($CLI_TOOL get ds $DS_NAME -n $NAMESPACE -o jsonpath='{.status.desiredNumberScheduled}')
  if [ "$desired" -eq "$ready" ] && [ "$desired" -ne 0 ]; then
    echo "DaemonSet completed, deleting"
    $CLI_TOOL -n $NAMESPACE delete ds $DS_NAME
    deleted=true
  fi
done

