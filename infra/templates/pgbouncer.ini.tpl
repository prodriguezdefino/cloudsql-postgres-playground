[databases]
* = host=${db_host} port=${db_port}

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = ${listen_port}
unix_socket_dir =
user = postgres
auth_file = /etc/pgbouncer/userlist.txt
auth_user = pgbouncer
auth_query = SELECT usename, passwd FROM pg_shadow WHERE usename ='\$1'

%{ if custom_config == "" ~}
max_db_connections = ${max_db_connections}
max_client_conn = ${max_client_conn}
pool_mode = ${pool_mode}
default_pool_size = ${default_pool_size}
admin_users = ${admin_users}
stats_users = ${admin_users}
ignore_startup_parameters = extra_float_digits, options
application_name_add_host = 1
max_prepared_statements = 10
server_login_retry = 1

%{~ else ~}
# Custom Config -------------------------------------------------------------- #

${custom_config}
%{~ endif ~}