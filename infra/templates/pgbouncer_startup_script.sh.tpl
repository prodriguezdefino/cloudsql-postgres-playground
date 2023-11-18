#!/usr/bin/env bash


sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

sudo apt-get update && sudo apt-get install -y pgbouncer

# pgbouncer service config
echo '${pgbouncer_config}' > /etc/pgbouncer/pgbouncer.ini
chown postgres /etc/pgbouncer/pgbouncer.ini

# pgbouncer users config
echo '${users_config}' > /etc/pgbouncer/userlist.txt
chown postgres /etc/pgbouncer/userlist.txt

systemctl stop pgbouncer.service
systemctl start pgbouncer.service
