#!/bin/bash
set -eu

if [ "$#" -ne 3 ]
  then
    echo "Usage : sh setup.sh <gcp project> <a run name> <migrated db ip>"
    exit -1
fi

PROJECT_ID=$1
RUN_NAME=$2
DB_IP=$3

pushd infra

terraform init && terraform apply \
  -var="run_name=${RUN_NAME}"     \
  -var="project=${PROJECT_ID}"    \
  -var="migrated_db_ip=${DB_IP}"  \
  -var="setup_dms=true"

popd