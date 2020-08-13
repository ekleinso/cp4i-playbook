Common Services

1. Get entitlement key - https://myibm.ibm.com/products-services/containerlibrary
2. Try to login with Docker

```
export ENTITLED_REGISTRY=cp.icr.io
export ENTITLED_REGISTRY_USER=cp
export ENTITLED_REGISTRY_KEY=<your key>
docker login -u $ENTITLED_REGISTRY_USER -p $ENTITLED_REGISTRY_KEY $ENTITLED_REGISTRY
docker pull $ENTITLED_REGISTRY/cp/icpa/icpa-installer:4.2.0
```

3. Add catalog sources
```yaml
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
```
```yaml
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
```

4. Subscribe to common services operator
```yaml
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
```
5. Wait for common services and odlm operator installs to complete <br>
   `oc -n openshift-operators get csv`

6. Install common services
```yaml
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
        - name: ibm-elastic-stack-operator
        - name: ibm-healthcheck-operator
        - name: ibm-management-ingress-operator
        - name: ibm-licensing-operator
        - name: ibm-metering-operator
        - name: ibm-commonui-operator
        - name: ibm-ingress-nginx-operator
        - name: ibm-auditlogging-operator
        - name: ibm-platform-api-operator
        - name: ibm-helm-api-operator
        - name: ibm-helm-repo-operator
        - name: ibm-catalog-ui-operator
      registry: common-service
EOF
```

7. Wait for common services <br>
```
  oc -n ibm-common-services get csv
  oc -n ibm-common-services get po`
```

8. Get URL and password
```
    echo "https://$(oc get route -n ibm-common-services cp-console -o jsonpath='{.spec.host}')"
    echo $(oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d)
```

