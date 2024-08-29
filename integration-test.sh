#!/bin/bash

# integration-test.sh

# Check if the environment argument is provided
if [ -z "$1" ]; then # Checks if the first positional argument ($1)
    echo "No environment specified. Please provide 'DEV' or 'PROD' as an argument."
    exit 1
fi

ENV=$1

# Sleep to allow time for services to start up
sleep 5s

# Set the port based on the environment
if [[ "$ENV" == "DEV" ]]; then
    PORT=$(kubectl -n default get svc ${serviceName} -o json | jq .spec.ports[].nodePort)
elif [[ "$ENV" == "PROD" ]]; then
    PORT=$(kubectl -n istio-system get svc istio-ingressgateway -o json | jq '.spec.ports[] | select(.port == 80)' | jq .nodePort)
else
    echo "Invalid environment specified. Please use 'DEV' or 'PROD'."
    exit 1
fi

# Output the determined port and construct the full URL
echo "Running Integrations tests on a $ENV environment at port $PORT"
echo "$applicationURL:$PORT/$applicationURI"

# Check if the service has a valid NodePort
if [[ ! -z "$PORT" ]]; then

    response=$(curl -s $applicationURL:$PORT$applicationURI)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" $applicationURL:$PORT$applicationURI)

    if [[ "$response" == 100 ]]; then
        echo "Increment Test Passed"
    else
        echo "Increment Test Failed"
        exit 1
    fi

    if [[ "$http_code" == 200 ]]; then
        echo "HTTP Status Code Test Passed"
    else
        echo "HTTP Status code is not 200"
        exit 1
    fi

else
    echo "The Service does not have a NodePort"
    exit 1
fi
