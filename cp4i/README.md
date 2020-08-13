# CP4I

1. Get entitlement key - https://myibm.ibm.com/products-services/containerlibrary

2. Try to login with Docker
```
export ENTITLED_REGISTRY=cp.icr.io
export ENTITLED_REGISTRY_USER=cp
export ENTITLED_REGISTRY_KEY=<your key>
docker login -u $ENTITLED_REGISTRY_USER -p $ENTITLED_REGISTRY_KEY $ENTITLED_REGISTRY
docker pull $ENTITLED_REGISTRY/cp/icpa/icpa-installer:4.2.0
```

3. Create cp4i project <br>
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

4. Create secret with entitlement key <br>
  ```
  oc create secret docker-registry ibm-entitlement-key --docker-username=${ENTITLED_REGISTRY_USER} --docker-password=${ENTITLED_REGISTRY_KEY} --docker-server=${ENTITLED_REGISTRY} --namespace=cp4i
  ```

5. Subscribe to platform navigator operator
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
6. Wait for operator <br>
   `oc -n cp4i get csv`

7. Create an instance of navigator
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

8. Subscribe to additional CP4I operators
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

oc -n openshift-operators delete subscription ibm-integration-asset-repository ibm-integration-operations-dashboard ibm-apiconnect ibm-appconnect ibm-eventstreams ibm-mq

oc -n cp4i delete PlatformNavigator cp4i-navigator
oc -n cp4i delete subscription ibm-integration-platform-navigator

