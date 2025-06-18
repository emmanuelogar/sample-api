#!/bin/bash

set -e  # Exit on error
set +x  # Don't print commands

helm template ./sample-api -f ../../.devcontainer/dev-values.yaml \
    | kubectl apply -f - 

# kubectl apply -f ../../static/deployment.yaml
# kubectl apply -f ../../static/service.yaml