# CloudSQL Postgres Playground

This project hosts a simple, Terraform based setup, for an example application that generates load (read and write transactions) in a Postgres SQL database hosted in GCP CloudSQL instance.

# Setup

To deploy the solution on GCP a local setup the gcloud is needed, and a user with enough priviledges to create the infrastructure in use for the test.

```bash
$ > sh setup.sh <gcp project> <run name>
```
