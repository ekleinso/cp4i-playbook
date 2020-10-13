#!/bin/bash

export ENTITLED_REGISTRY=cp.icr.io
export ENTITLED_REGISTRY_USER=cp
export ENTITLED_REGISTRY_KEY=<your key>

echo "Creating project"
oc new-project cp4i

echo "Creating ibm-entitlement-key"
oc create secret docker-registry ibm-entitlement-key --docker-username=${ENTITLED_REGISTRY_USER} --docker-password=${ENTITLED_REGISTRY_KEY} --docker-server=${ENTITLED_REGISTRY} --namespace=cp4i
 
echo "Creating subscription"
oc apply -f 02-cp4i-subscription.yaml

echo -n "waiting for cp4i Platform Navigator subscription"
while [ "$(oc -n cp4i get csv --no-headers -o custom-columns=NAME:.metadata.name,PHASE:.status.phase | grep ibm-integration-platform-navigator | awk '{print $2}')" != "Succeeded" ]
do
  echo -n "."
done
echo -e "\nIBM Cloud Pak for Integration Platform Navigator subscription succeeded"

echo "Creating Platform Navigator"
oc apply -f 03-platform-navigator-install.yaml

echo "Subscribing to CP4I Operators"
oc apply -f 04-additional-cp4i-operators.yaml

if [ $(oc get --namespace openshift-ingress-operator ingresscontrollers/default --output jsonpath='{.status.endpointPublishingStrategy.type}') == "HostNetwork" ]
then
  oc label namespace default network.openshift.io/policy-group=ingress
fi

