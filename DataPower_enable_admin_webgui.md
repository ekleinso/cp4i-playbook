## Enable DataPower Web GUI

1. Create DP Service make sure to specify persistent storage. The yaml looks like this.

```yaml
storage:
  - class: <storage class name>
    deleteClaim: true
    path: /opt/ibm/datapower/drouter/config
    size: '10G'
    type: persistent
```
2. Once service is running enable admin web gui

```shell
$ oc attach -i -t <DP Pod Name> -c datapower
login: admin
Password: ********
idg# co
idg(config)# web-m
idg(config web-mgmt)# admin-state enabled
idg(config web-mgmt)# exit
idg(config)# write mem
```
3. Create service for admin gui

```yaml
kind: Service
apiVersion: v1
metadata:
  name: <DP podname>-admingui
  namespace: cp4i
spec:
  ports:
    - protocol: TCP
      port: 9090
      targetPort: 9090
  selector:
    app.kubernetes.io/instance: cp4i-<DP instance name>
    app.kubernetes.io/name: datapower
  type: ClusterIP
  sessionAffinity: None
```
4. Expose service

```shell
oc create route passthrough <route name> --service=<DP podname>-admingui
```
5. Connect with browser using the route hostname

```shell
oc get route <route name> -o jsonpath='{.spec.host}'
```
6. Repeat steps 2-4 for each replica pod in the statefull set you wish to access.

