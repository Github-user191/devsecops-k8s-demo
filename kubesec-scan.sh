#!/bin/bash

# using kubesec v2 api to scan our manifest file
# jq is a JSON processor to grab the response of the scan and decide to pass or fail the build
scan_result=$(curl -sSX POST --data-binary @"k8s_DEV-deployment_service.yaml" https://v2.kubesec.io/scan)
scan_message=$(curl -sSX POST --data-binary @"k8s_DEV-deployment_service.yaml" https://v2.kubesec.io/scan | jq .[0].message -r )
scan_score=$(curl -sSX POST --data-binary @"k8s_DEV-deployment_service.yaml" https://v2.kubesec.io/scan | jq .[0].score )


# using kubesec docker image for scanning
# scan_result=$(docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < k8s_DEV-deployment_service.yaml)
# scan_message=$(docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < k8s_DEV-deployment_service.yaml | jq .[].message -r)
# scan_score=$(docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < k8s_DEV-deployment_service.yaml | jq .[].score)


	if [[ "${scan_score}" -ge 5 ]]; then
	    echo "Score is $scan_score"
	    echo "Kubesec Scan $scan_message"
	else
	    echo "Score is $scan_score, which is less than or equal to 5."
	    echo "Scanning Kubernetes Resource has Failed"
	    exit 1;
	fi;