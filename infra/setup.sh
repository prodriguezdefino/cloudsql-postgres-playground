#!/bin/bash
set -eu

if [ "$#" -ne 2 ]
  then
    echo "Usage : sh setup.sh <gcp project> <a run name>"
    exit -1
fi

PROJECT=$1
NAME=$2

terraform init && terraform apply \
  -var="run_name=${NAME}"           \
  -var="project=${PROJECT}"