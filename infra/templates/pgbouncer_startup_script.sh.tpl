#!/usr/bin/env bash

sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

sudo apt-get update && sudo apt-get install -y pgbouncer postgresql-client

#
ENC=$(psql -qtAX -d "dbname='postgres' user='postgres' password='${pg_psswd}' host='${pg_ip}'" -c "SHOW password_encryption;")
if [ "$ENC" = "on" ]
then
    ENC="md5"
fi

PWD=$(psql -qtAX -d "dbname='postgres' user='pgbouncer' password='${pg_psswd}' host='${pg_ip}'" -c "SELECT passwd FROM pg_shadow WHERE usename ='pgbouncer';")

# pgbouncer service config
echo '${pgbouncer_config}' > /etc/pgbouncer/pgbouncer.ini
echo "auth_type = $ENC" >> /etc/pgbouncer/pgbouncer.ini
chown postgres /etc/pgbouncer/pgbouncer.ini

# pgbouncer users config
echo "\"pgbouncer\" \"$PWD\"" > /etc/pgbouncer/userlist.txt
chown postgres /etc/pgbouncer/userlist.txt

systemctl stop pgbouncer.service
systemctl start pgbouncer.service

sleep 1

psql -d "dbname='postgres' user='pgbouncer' password='${pg_psswd}' host='localhost'" -c "SHOW password_encryption;"