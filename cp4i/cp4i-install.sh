#!/bin/bash

export ENTITLED_REGISTRY=cp.icr.io
export ENTITLED_REGISTRY_USER=cp
export ENTITLED_REGISTRY_KEY=<your key>


cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: cp4i
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-monitoring: "true"
EOF

oc create secret docker-registry ibm-entitlement-key --docker-username=${ENTITLED_REGISTRY_USER} --docker-password=${ENTITLED_REGISTRY_KEY} --docker-server=${ENTITLED_REGISTRY} --namespace=cp4i

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  annotations:
    olm.providedAPIs: CommonService.v3.operator.ibm.com
  name: common-services
  namespace: cp4i
spec:
  targetNamespaces:
  - cp4i
EOF

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-integration-platform-navigator
  namespace: cp4i
spec:
  channel: v4.0
  installPlanApproval: Automatic
  name: ibm-integration-platform-navigator
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
  startingCSV: ibm-integration-platform-navigator.v4.0.0
EOF

echo -n "waiting for cp4i Platform Navigator "
while [ "$(oc -n cp4i get csv --no-headers -o custom-columns=NAME:.metadata.name,PHASE:.status.phase | grep ibm-integration-platform-navigator | awk '{print $2}')" != "Succeeded" ]
do
  echo -n "."
done
echo -e "\nIBM Cloud Pak for Integration Platform Navigator install succeeded"

cat <<EOF | oc apply -f -
apiVersion: integration.ibm.com/v1beta1
kind: PlatformNavigator
metadata:
  name: cp4i-navigator
  namespace: cp4i
spec:
  license:
    accept: true
  mqDashboard: true
  replicas: 3
  version: 2020.2.1
EOF

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-mq
  namespace: openshift-operators
spec:
  channel: v1.1
  installPlanApproval: Automatic
  name: ibm-mq
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
  startingCSV: ibm-mq.v1.1.0
EOF

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-eventstreams
  namespace: openshift-operators
spec:
  channel: v2.0
  installPlanApproval: Automatic
  name: ibm-eventstreams
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
  startingCSV: ibm-eventstreams.v2.0.1
EOF

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-appconnect
  namespace: openshift-operators
spec:
  channel: v1.0
  installPlanApproval: Automatic
  name: ibm-appconnect
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
  startingCSV: ibm-appconnect.v1.0.2
EOF

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-apiconnect
  namespace: openshift-operators
spec:
  channel: v1.0
  installPlanApproval: Automatic
  name: ibm-apiconnect
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
  startingCSV: ibm-apiconnect.v1.0.1
EOF

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-integration-operations-dashboard
  namespace: openshift-operators
spec:
  channel: v1.0
  installPlanApproval: Automatic
  name: ibm-integration-operations-dashboard
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
  startingCSV: ibm-integration-operations-dashboard.v1.0.0
EOF

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-integration-asset-repository
  namespace: openshift-operators
spec:
  channel: v1.0
  installPlanApproval: Automatic
  name: ibm-integration-asset-repository
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
  startingCSV: ibm-integration-asset-repository.v1.0.0
EOF

