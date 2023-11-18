# CloudSQL Postgres Playground

This project hosts a simple, Terraform based setup, for an example application that generates load (read and write transactions) in a Postgres SQL database hosted in GCP CloudSQL instance.

# Setup

To deploy the components of this playground on GCP, a local setup the gcloud is needed, and a user with enough priviledges to create the infrastructure in use for the test.

```bash
# creates the initial components, network, database (public ip), pgbouncer and client application.
$ > sh 1-setup.sh <gcp project> <run name>

# enables private ip setup for the database, changes pgbouncer setup and creates connections for future DMS migrations
$ > sh 2-enable-privateip-dms.sh <gcp project> <run name>

# cleans up the components
$ > sh 3-cleanup.sh <gcp project> <run name>
```
