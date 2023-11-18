[databases]
* = host=${db_host} port=${db_port}

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = ${listen_port}
unix_socket_dir =
user = postgres
auth_file = /etc/pgbouncer/userlist.txt
auth_type = md5

%{ if custom_config == "" ~}
max_db_connections = ${max_db_connections}
max_client_conn = ${max_client_conn}
pool_mode = ${pool_mode}
default_pool_size = ${default_pool_size}
admin_users = ${admin_users}
stats_users = ${admin_users}
ignore_startup_parameters = extra_float_digits, options
application_name_add_host = 1

%{~ else ~}
# Custom Config -------------------------------------------------------------- #

${custom_config}
%{~ endif ~}