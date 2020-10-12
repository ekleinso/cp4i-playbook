#!/bin/bash
# ----------------------------------------------------------------------------------------------------\\
# Description:
#   A ridiculous script to get rid of one or more namespace(s) stuck in terminating state for a ROKS CP4MCM Env
#
#   Options:
#     STUCKNAMESPACE:  Namespace targetted for removal
#
#   Author: joshisa(at)us.ibm.com
#
#   Example:
#     ./delete-stuck-namespace.sh STUCKNAMESPACE
#
#   Reference: 
#     https://stackoverflow.com/questions/46302126/how-to-stop-kubectl-proxy
#     https://github.com/kubernetes/kubernetes/issues/77086#issuecomment-569663112
#
# ----------------------------------------------------------------------------------------------------\\

############
# Colors  ##
############
Green='\x1B[0;32m'
Red='\x1B[0;31m'
Yellow='\x1B[0;33m'
Cyan='\x1B[0;36m'
no_color='\x1B[0m' # No Color
beer='\xF0\x9f\x8d\xba'
delivery='\xF0\x9F\x9A\x9A'
beers='\xF0\x9F\x8D\xBB'
eyes='\xF0\x9F\x91\x80'
cloud='\xE2\x98\x81'
crossbones='\xE2\x98\xA0'
litter='\xF0\x9F\x9A\xAE'
fail='\xE2\x9B\x94'
harpoons='\xE2\x87\x8C'
tools='\xE2\x9A\x92'
present='\xF0\x9F\x8E\x81'
#############

set -e

clear

USAGE="${crossbones}\t${eyes}  Usage: ./${0##*/} STUCKNAMESPACE\n
\tSTUCK NAMESPACE:\tNAMESPACE stuck in terminating state\n"


echo -e "${tools}   Welcome to the ridiculous Stuck Namespace Remover script for ROKS CloudPak for MCM";
if [ $# -lt 1 ]; then
  echo -e $USAGE
  kubectl get ns | grep "Terminating"
  exit 1
fi

STUCKNAMESPACE="${1}"

if [ "${OSTYPE}" == "rhel" ]; then
  sudo yum install epel-release -y
  sudo yum install jq -y
elif [[ "${OSTYPE}" == "darwin"* ]]; then
  brew install jq 2>/dev/null && true;
else
  sudo apt-get -qq install jq -y
fi

# Fire up the kubectl proxy to access the API
kubectl proxy > /dev/null 2>&1 &

# Let's make the argument match test case insensitive
shopt -s nocasematch

if [[ "${STUCKNAMESPACE}" == ALL ]]
then
  if [[ $(kubectl get ns | grep "Terminating" | wc -l) -lt 1 ]]; then
    echo -e "${eyes} ${beer}  There are no namespaces stuck in the terminating state.  Congratulations. It's your lucky day!"
    exit 0
  fi
 
  echo -e "${delivery} Deleting the following stuck namespaces ..."
  kubectl get ns | grep "Terminating" | awk '{print "Namespace:\t\xE2\x98\xA0   " $1}'
  kubectl get ns | grep "Terminating" | awk '{print $1}' | \
  xargs -L 1 -- sh -c 'kubectl get ns $1 -o json | jq ".spec.finalizers=[]" | curl -s -X PUT http://localhost:8001/api/v1/namespaces/$1/finalize -H "Content-Type: application/json" --data @- > /dev/null' _
else
  echo -e "${crossbones}  Deleting the stuck namespace named ${STUCKNAMESPACE}"
  kubectl get ns ${STUCKNAMESPACE} -o json | \
  jq '.spec.finalizers=[]' | \
  curl -s -X PUT http://localhost:8001/api/v1/namespaces/${STUCKNAMESPACE}/finalize -H "Content-Type: application/json" --data @- > /dev/null
fi

# Kill the kubectl proxy that is running in the background
if [ "${OSTYPE}" == "rhel" ]; then
  echo -e "No process kill command for kubectl proxy defined for RHEL.  Updates welcome."
  echo -e "You will need to kill the process yourself"
  ps -ef | grep "kubectl proxy"
elif [[ "${OSTYPE}" == "darwin"* ]]; then
  pkill -9 -f "kubectl proxy"
else
  echo -e "No process kill command for kubectl proxy defined for non-RHEL/non-OSX.  Updates welcome."
  echo -e "You will need to kill the process yourself"
  ps -ef | grep "kubectl proxy"
fi

