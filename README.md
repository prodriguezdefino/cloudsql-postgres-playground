# CloudSQL Postgres Playground

This project hosts a simple, Terraform based, setup for an example application that generates load (read and write transactions) in a Postgres SQL database hosted in GCP CloudSQL instance. The goal is to exemplify how an upgrade migration of the underlying database engine can be executed.

# Simulate the migration process

## Initial Setup
To deploy the components of this playground on GCP, a local setup the gcloud is needed, and a user with enough priviledges to create the infrastructure in use for the test.

```bash
# creates the initial components, network, database (public ip), pgbouncer and client application.
$ > sh 1-setup.sh <gcp project> <run name>
```

After the execution the test application should be running in the GCE instance with name `testapp-<run name>-1`, this application will execute repeatedly 3 queries and 1 write operation on the database, concurrently across many different threads. By default, the application uses 100 concurrent threads and will execute for 24hrs. This setup should achieve between 7000 and 9000 row operations per second.

The test application prints on console performance metrics, using the command `gcloud compute --project=pabs-pso-lab instances get-serial-port-output testapp-<run name>-1 --zone=us-central1-a --port=1` we can print on the console the logs from the app, possibly seeing the metrics:

```bash
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script: -- Counters --------------------------------------------------------------------
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script: com.google.cloud.pso.RetryHelper.inserts.error.count
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:              count = 0
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script: com.google.cloud.pso.RetryHelper.inserts.exhaust.count
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:              count = 0
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script: com.google.cloud.pso.RetryHelper.inserts.retry.count
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:              count = 0
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script: -- Histograms ------------------------------------------------------------------
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script: com.google.cloud.pso.RentalProcessor.inserts.latency.ms
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:              count = 11220713
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:                min = 6
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:                max = 22
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:               mean = 10.71
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:             stddev = 2.45
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:             median = 10.00
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:               75% <= 12.00
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:               95% <= 16.00
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:               98% <= 17.00
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:               99% <= 18.00
Nov 21 22:34:53 debian google_metadata_script_runner[899]: startup-script:             99.9% <= 22.00

```

## Setup private connectivity for source database

Given that the database is configured using a public IP address, we can now simulate the effects of changing this configuration for the database setting a private connectivity.

```bash
# enables private ip setup for the database, changes pgbouncer setup and creates connections for future DMS migrations
$ > sh 2-enable-privateip-dms.sh <gcp project> <run name>
```

After the enablement of the private setup, the test application should have been able to recover automatically using the new connection profile on `pg_bouncer`, possibly increased the number of operations slightly (given now that the latency per operation is smaller).

## Kick off data migration

We can now setup a DMS migration, to move the data to a new upgraded instance (Postgres or AlloyDB). On how to setup the migration process follow the instructions [here](https://cloud.google.com/database-migration/docs/postgres/quickstart). All the databases in use and connections needed for the migration job should already be present and able to be used. During the process of the migration job setup a new destination instance will be created, select a private IP for simplicity on the setup/cleanup later on.

While the new instance is create, we will recommend to include some configurations:
 * create a `pgbouncer` user with the desided password (by default this setup uses `somepassword`, but this can be changed)
 * setup the database flag `cloudsql.pg_shadow_select_role = pgbouncer` that will enable this user to query the `pg_shadow` table.

This can be done later, but this way the cutover will be smoother.

## Cutover

Once the DMS job is running we just need to wait for the lag latency to approach to 0 and make the cutover to have the application writing to the new destination.

For this, we can extract the new destination database IP from the web console and run the next script"

```bash
# updates the pg_bouncer connectivity to the new database
$ > sh 3-setup-migrated-db.sh <gcp project> <run name> <new db IP>
```

After running the script, the test application will start to fail it's transactions, this is expected since the DMS job is still running and the new destination database does not accepts connections.

## New database promotion

For it to recover we will need to promote the new migrated destination database using the the process described [here](https://cloud.google.com/database-migration/docs/postgres/promote-migration).

Once restarting the pgbouncer instance, the new database should start to accept connections, recovering the test application clients with it.

## Cleanup

Once the migration process is completed, running the following script, the GCP resources created will be destroyed.

```bash
# cleans up the components
$ > sh 4-cleanup.sh <gcp project> <run name>
```

The new destination Database created by DMS should be destroyed manually, since it was created outside the scope of our Terraform based scripts.
