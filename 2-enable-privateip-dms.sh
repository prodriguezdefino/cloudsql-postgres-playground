#!/bin/bash
set -eu

if [ "$#" -ne 2 ]
  then
    echo "Usage : sh setup.sh <gcp project> <a run name>"
    exit -1
fi

PROJECT_ID=$1
RUN_NAME=$2

pushd infra

source setup.sh $PROJECT_ID $RUN_NAME true

popd