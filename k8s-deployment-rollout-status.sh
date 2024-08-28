#!/bin/bash
sleep 60s

# Usage: ./k8s-deployment-rollout-status.sh <namespace>

# Check if the correct number of arguments are provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <namespace>"
  exit 1
fi

# Assign arguments to variables
namespace=$1

echo "Namespace is: $1"

if [[ $(kubectl -n "${namespace}" rollout status deploy ${deploymentName} --timeout 5s) != *"successfully rolled out"* ]];
then
	echo "Deployment ${deploymentName} Rollout has Failed"
    kubectl -n "${namespace}" rollout undo deploy ${deploymentName}
    exit 1;
else
	echo "Deployment ${deploymentName} Rollout is Success"
fi