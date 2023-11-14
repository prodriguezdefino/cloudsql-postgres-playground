#!/bin/bash
set -eu

if [ "$#" -ne 2 ]
  then
    echo "Usage : sh destroy.sh <gcp project> <a run name>"
    exit -1
fi

PROJECT_ID=$1
RUN_NAME=$2

terraform destroy \
  -var="run_name=${RUN_NAME}"           \
  -var="project=${PROJECT_ID}"
