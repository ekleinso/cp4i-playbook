# CP4I

1. Login to Openshift
```
oc login
```

2. Get entitlement key - https://myibm.ibm.com/products-services/containerlibrary

3. Try to login with Docker
```
export ENTITLED_REGISTRY=cp.icr.io
export ENTITLED_REGISTRY_USER=cp
export ENTITLED_REGISTRY_KEY=<your entitlement key>
docker login -u $ENTITLED_REGISTRY_USER -p $ENTITLED_REGISTRY_KEY $ENTITLED_REGISTRY
docker pull $ENTITLED_REGISTRY/cp/icpa/icpa-installer:4.2.0
```

4. Configure NetworkPolicy<br>
Run command:
```
oc get --namespace openshift-ingress-operator ingresscontrollers/default --output jsonpath='{.status.endpointPublishingStrategy.type}'
```
If the result is **HostNetwork** then run:
```
oc label namespace default 'network.openshift.io/policy-group=ingress'
```
Note: More details on configuration provided in [Openshift Docs](https://docs.openshift.com/container-platform/4.5/networking/network_policy/about-network-policy.html)

5. Create cp4i project <br>
   `oc new-project cp4i` <br>
or
```yaml
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
```

6. Create secret with entitlement key <br>
  ```
  oc create secret docker-registry ibm-entitlement-key --docker-username=${ENTITLED_REGISTRY_USER} --docker-password=${ENTITLED_REGISTRY_KEY} --docker-server=${ENTITLED_REGISTRY} --namespace=cp4i
  ```

7. Subscribe to platform navigator operator
```yaml
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
```
```yaml
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
  startingCSV: ibm-integration-platform-navigator.v4.0.1
EOF
```
8. Wait for operator <br>
   `oc -n cp4i get csv`

9. Create an instance of navigator
```yaml
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
```

10. Subscribe to additional CP4I operators
```yaml
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
```
```yaml
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
```
```yaml
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
  startingCSV: ibm-appconnect.v1.0.3
EOF
```
```yaml
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
  startingCSV: ibm-apiconnect.v1.0.2
EOF
```
```yaml
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
```
```yaml
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
  startingCSV: ibm-integration-asset-repository.v1.0.1
EOF
```

