#!/bin/bash

echo "apply common service operator catalog"
oc apply -f 01-common-service-catalog.yaml

echo "apply ibm operator catalog"
oc apply -f 02-ibm-operator-catalog.yaml

echo "create ibm-common-services-operator namespace"
oc create project ibm-common-services-operator

echo "create ibm common services subscription"
oc apply -f 04-common-service-subscription.yaml

echo -n "ibm-common-service-operator initializing "
while [ "$(oc -n ibm-common-services-operator get csv --no-headers -o custom-columns=NAME:.metadata.name,PHASE:.status.phase | grep ibm-common-service-operator | awk '{print $2}')" != "Succeeded" ]
do
  echo -n "."
done
echo -e "\nibm-common-service-operator Succeeded"

echo -n "operand-deployment-lifecycle-manager initializing "
while [ "$(oc -n ibm-common-services-operator get csv --no-headers -o custom-columns=NAME:.metadata.name,PHASE:.status.phase | grep operand-deployment-lifecycle-manager | awk '{print $2}')" != "Succeeded" ]
do
  echo -n "."
  sleep 10
done
echo -e "\noperand-deployment-lifecycle-manager Succeeded"

echo "setting size of common services"
oc apply -f 05-commonservice-size.yaml

echo "installing common services"
oc apply -f 06-common-service-install.yaml

echo -n "waiting for common services "
while [ "$(oc -n ibm-common-services get csv --no-headers | grep -v -c Succeeded)" != "0" ]
do
  echo -n "."
  sleep 10
done
echo -e "\nIBM Common Services install succeeded"

echo -n "waiting for common services pods "
while [ "$(oc -n ibm-common-services get po --no-headers | grep -v Running | grep -v Completed | wc -l)" != "0" ]
do
  echo -n "."
  sleep 10
done
echo -e "\nIBM Common Services pods running"

echo "https://$(oc get route -n ibm-common-services cp-console -o jsonpath='{.spec.host}')"
echo $(oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d)

