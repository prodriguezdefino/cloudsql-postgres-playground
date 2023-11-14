#!/bin/bash
set -eu

if [ "$#" -ne 1 ]
  then
    echo "Usage : sh setup.sh <bucket name>"
    exit -1
fi

BUCKET_NAME=$1

mvn clean package
gsutil cp target/postgres-migration-test-app-bundled-* gs://$BUCKET_NAME/jar/