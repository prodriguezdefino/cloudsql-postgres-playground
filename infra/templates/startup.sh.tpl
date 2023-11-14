sudo apt-get update && sudo apt-get install -y postgresql-client
cd /tmp
curl https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb >> jdk-21_linux-x64_bin.deb
sudo dpkg -i jdk-21_linux-x64_bin.deb

psql -d "dbname='${db_name}' user='postgres' password='${pg_psswd}' host='${pg_public_ip}'" -c 'SELECT FROM 'public.rental' LIMIT 1;'
DB_EXISTS=$?

if [ $DB_EXISTS -ne 0 ]; then
    echo "Database does not exists"
    curl https://www.postgresqltutorial.com/wp-content/uploads/2019/05/dvdrental.zip | jar xv
    pg_restore -d "dbname='${db_name}' user='postgres' password='${pg_psswd}' host='${pg_public_ip}'" -c --verbose "/tmp/dvdrental.tar"
    # change owner to postgres so we can delete later on
    psql -d "dbname='${db_name}' user='postgres' password='${pg_psswd}' host='${pg_public_ip}'" -c 'ALTER DATABASE "${db_name}" OWNER TO cloudsqlsuperuser;'
    # this are all needed for the replication job, besides the specific flags needed at instance creation time
    psql -d "user='postgres' password='${pg_psswd}' host='${pg_public_ip}'" -c 'ALTER USER postgres WITH REPLICATION;'
    psql -d "dbname='${db_name}' user='postgres' password='${pg_psswd}' host='${pg_public_ip}'" -c 'CREATE EXTENSION pglogical;'
    psql -d "dbname='${db_name}' user='postgres' password='${pg_psswd}' host='${pg_public_ip}'" -c 'CREATE EXTENSION pglogical;'
fi

gsutil cp gs://${bucket_name}/jar/* .
java -jar postgres-migration-test-app-bundled-1.1-SNAPSHOT.jar \
 -db ${db_name} \
 -usr postgres \
 -pwd ${pg_psswd} \
 -instance ${instance_name} &