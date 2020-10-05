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
  startingCSV: ibm-integration-platform-navigator.v4.0.2
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
  version: 2020.3.1
EOF

oc apply -f 05-additional-cp4i-operators.yaml

