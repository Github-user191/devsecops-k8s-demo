#!/bin/bash

# Usage: ./k8s-deployment.sh <manifestFile> <namespace>

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <manifestFile> <namespace>"
  exit 1
fi

# Assign arguments to variables
manifestFile=$1
namespace=$2

# Replace Image name inside the Kubernetes Manifest file, its currently set to "replace"
sed -i "s#replace#${imageName}#g" "${manifestFile}"
# Apply the manifest file to the specified namespace
kubectl -n "${namespace}" apply -f "${manifestFile}"