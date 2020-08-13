#!/bin/bash

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: opencloud-operators
  namespace: openshift-marketplace
spec:
  displayName: IBMCS Operators
  publisher: IBM
  sourceType: grpc
  image: docker.io/ibmcom/ibm-common-service-catalog:latest
  updateStrategy:
    registryPoll:
      interval: 45m
EOF

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: ibm-operator-catalog 
  publisher: IBM Content
  sourceType: grpc
  image: docker.io/ibmcom/ibm-operator-catalog
  updateStrategy:
    registryPoll:
      interval: 45m
EOF

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-common-service-operator
  namespace: openshift-operators
spec:
  channel: stable-v1
  installPlanApproval: Automatic
  name: ibm-common-service-operator
  source: opencloud-operators
  sourceNamespace: openshift-marketplace
  startingCSV: ibm-common-service-operator.v3.4.3
EOF

echo -n "ibm-common-service-operator initializing "
while [ "$(oc -n openshift-operators get csv --no-headers -o custom-columns=NAME:.metadata.name,PHASE:.status.phase | grep ibm-common-service-operator | awk '{print $2}')" != "Succeeded" ]
do
  echo -n "."
done
echo -e "\nibm-common-service-operator Succeeded"

echo -n "operand-deployment-lifecycle-manager initializing "
while [ "$(oc -n openshift-operators get csv --no-headers -o custom-columns=NAME:.metadata.name,PHASE:.status.phase | grep operand-deployment-lifecycle-manager | awk '{print $2}')" != "Succeeded" ]
do
  echo -n "."
  sleep 10
done
echo -e "\noperand-deployment-lifecycle-manager Succeeded"

cat <<EOF | oc apply -f -
apiVersion: operator.ibm.com/v1alpha1
kind: OperandRequest
metadata:
  name: common-service
  labels:
    app.kubernetes.io/instance: operand-deployment-lifecycle-manager
    app.kubernetes.io/managed-by: operand-deployment-lifecycle-manager
    app.kubernetes.io/name: odlm
  namespace: ibm-common-services
spec:
  requests:
    - operands:
        - name: ibm-cert-manager-operator
        - name: ibm-mongodb-operator
        - name: ibm-iam-operator
        - name: ibm-monitoring-exporters-operator
        - name: ibm-monitoring-prometheusext-operator
        - name: ibm-monitoring-grafana-operator
        - name: ibm-healthcheck-operator
        - name: ibm-management-ingress-operator
        - name: ibm-licensing-operator
        - name: ibm-metering-operator
        - name: ibm-commonui-operator
        - name: ibm-elastic-stack-operator
        - name: ibm-ingress-nginx-operator
        - name: ibm-auditlogging-operator
        - name: ibm-platform-api-operator
        - name: ibm-helm-api-operator
        - name: ibm-helm-repo-operator
        - name: ibm-catalog-ui-operator
      registry: common-service
EOF


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

