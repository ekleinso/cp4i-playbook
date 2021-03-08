# Notes for installation of IBM Cloud Pak for Integration

These notes are meant to supplement the information found in these links: <br>
https://cloudpak8s.io/integration/cp4i-install-latest/ <br>
https://www.ibm.com/support/knowledgecenter/SSGT7J_20.2/install/install.html

This repo is broken down into 3 directories.<br>
- common-services - contains yaml for deploying Common Services using Operators
- cp4i - contains yaml for deploying Cloud Pak for Integration using Operators
- scripts - contains some utility scripts that may come in handy.

# Common Services
These instructions were followed to install IBM Common Services v3.5.4. Not much changed with these files from previous versions used to install so in most cases updating the versions in the yaml files should be enough to install newer versions or you can just let the operator automatically update itself to the latest version.

In the common-services directory are several yaml files numbered 1-6
- 01-common-service-catalog.yaml
- 02-ibm-operator-catalog.yaml
- 03-namespace.yaml  
- 04-common-service-subscription.yaml  
- 05-commonservice-size.yaml  
- 06-common-service-install.yaml

The installation is rather straight forward you just apply each file in order using the OC command. The `cs_install.sh` script that is in that same directory attempts to put some automation around the installation complete with checks for components being completed before moving on to the next step, but it has not been fully tested. I was using it in place of this documentation to walk me through the installation.
1. Apply common service operator catalog
```shell
oc apply -f 01-common-service-catalog.yaml
```

2. Apply IBM operator catalog
```shell
oc apply -f 02-ibm-operator-catalog.yaml
```

3. Create ibm-common-services-operator namespace. I diverge a little from the documentation here that suggests creating a **common-services project**. I prefer using **ibm-common-services-operator** as it fits in better with the conventions Red Hat follows to deploy operators.
```shell
oc new-project ibm-common-services-operator
```
or
```shell
oc apply -f 03-namespace.yaml
```
If you wish to change it back to **common-services** just keep in mind you will have to update the remaining yaml files.
4. Create IBM common services subscription
```shell
oc apply -f 04-common-service-subscription.yaml
```
wait for the subscription install to complete
```shell
oc -n ibm-common-services get csv
```
There should be 2; **ibm-common-service-operator** and **operand-deployment-lifecycle-manager**

5. Setting size of common services.
```shell
oc apply -f 05-commonservice-size.yaml
```
The default size for common services is medium and that is what is configured in the yaml file. So if you do not wish to change from the default you can skip this step. If this is a development/sandbox installation you can save some resources by changing the size to **small** which will deploy single replicas of the components and reduce some of the resource requirements.

```yaml
apiVersion: operator.ibm.com/v3
kind: CommonService
metadata:
  name: common-service
  namespace: ibm-common-services
spec:
  size: small
```

6. Install common services
```shell
oc apply -f 06-common-service-install.yaml
```

7. Wait for common services operators to be installed
```shell
oc -n ibm-common-services get csv
```

8. Wait for pods to be running. This command will show what pods are still in progress.
```shell
oc -n ibm-common-services get po | grep -v Running | grep -v Completed
```

9. Get console url and admin password
```shell
echo "https://$(oc get route -n ibm-common-services cp-console -o jsonpath='{.spec.host}')"
echo $(oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d)
```

# IBM Cloud Pak for Integration
These instructions were followed to install IBM Cloud Pak for Integration v2020.3.1. Not much changed with these files from previous versions used to install so in most cases updating the versions in the yaml files should be enough to install newer versions or you can just let the operator automatically update itself to the latest version.

In the cp4i directory are several yaml files numbered 1-4
- 01-namespace.yaml  
- 02-cp4i-subscription.yaml  
- 03-platform-navigator-install.yaml  
- 04-additional-cp4i-operators.yaml

The installation is rather straight forward you just apply each file in order using the OC command. The `cp4i_install.sh` script that is in that same directory attempts to put some automation around the installation complete with checks for components being completed before moving on to the next step, but it has not been fully tested. I was using it in place of this documentation to walk me through the installation.
1. Create project
```shell
oc new-project cp4i
```
or
```shell
oc apply -f 01-namespace.yaml
```

2. Create ibm-entitlement-key
```shell
oc create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-password=<your entitlement key> --docker-server=cp.icr.io --namespace=cp4i
```

3. Create subscription
```shell
oc apply -f 02-cp4i-subscription.yaml
```

4. Wait for subscription
```shell
oc -n cp4i get csv | grep ibm-integration-platform-navigator
```

5. Create Platform Navigator
```shell
oc apply -f 03-platform-navigator-install.yaml
```
If this is a development/sandbox environment you can change the number of replicas to save on resources

```yaml
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
```

6. Subscribe to remaining CP4I Operators
```shell
oc apply -f 04-additional-cp4i-operators.yaml
```

7. Check **endpointPublishingStrategy** to determine if additional configuration is required due to network policy. It was found that with many on-prem installations this setting must be made or the CP4I consoles will not work.
```shell
oc get --namespace openshift-ingress-operator ingresscontrollers/default --output jsonpath='{.status.endpointPublishingStrategy.type}'
```
If the output from the above command is **HostNetwork** run this command.
```shell
oc label namespace default network.openshift.io/policy-group=ingress
```
Additional information regarding this configuration and why it might be required is available in the [Red Hat Documentation](https://docs.openshift.com/container-platform/4.5/networking/network_policy/about-network-policy.html)

