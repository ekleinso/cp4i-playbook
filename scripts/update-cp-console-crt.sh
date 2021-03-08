#!/bin/bash
CRT_FN=$1
KEY_FN=$2
CABUNDLE_FN=/home/emk/code/terraform-ocp/certs/ca.crt.pem

CERTIFICATE="$(awk '{printf "%s\\n", $0}' ${CRT_FN})"
KEY="$(awk '{printf "%s\\n", $0}' ${KEY_FN})"
CABUNDLE="$(awk '{printf "%s\\n", $0}' ${CABUNDLE_FN})"

echo $CERTIFICATE
echo $KEY
echo $CABUNDLE

#oc patch -n ibm-common-services "route/cp-console" -p '{"spec":{"tls":{"certificate":"'"${CERTIFICATE}"'","key":"'"${KEY}"'","caCertificate":"'"${CABUNDLE}"'"}}}'
