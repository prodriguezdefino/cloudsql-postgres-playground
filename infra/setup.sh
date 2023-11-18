#!/bin/bash
set -eu

if [ "$#" -ne 2 ] && [ "$#" -ne 3 ]
  then
    echo "Usage : sh setup.sh <gcp project> <a run name> <optional boolean: setup dms>"
    exit -1
fi

PROJECT=$1
NAME=$2
SETUP_DMS=false

if (( $# == 3 ))
then
  SETUP_DMS=true
fi

terraform init && terraform apply \
  -var="run_name=${NAME}"         \
  -var="project=${PROJECT}"       \
  -var="setup_dms=${SETUP_DMS}"