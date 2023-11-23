#!/bin/bash
set -eu

if [ "$#" -ne 2 ]
  then
    echo "Usage : sh cleanup.sh <gcp project> <a run name>"
    exit -1
fi

PROJECT_ID=$1
RUN_NAME=$2

pushd infra

source destroy.sh $PROJECT_ID $RUN_NAME

popd