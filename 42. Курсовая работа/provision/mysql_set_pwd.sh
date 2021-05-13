#!/bin/bash

cur_pwd=$(grep temporary /var/log/mysqld.log | sed 's/.*root@localhost. //')
mysql --user=root --password=$cur_pwd --connect-expired-password --execute "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Otus_2020';"

# systemctl stop mysqld
# echo "Mysql is Stop"
# systemctl set-environment MYSQLD_OPTS="--skip-grant-tables"
# echo "set env"
# systemctl start mysqld

# mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Otus2020';"
# systemctl stop mysqld
# echo "Mysql is Stop"
# systemctl unset-environment MYSQLD_OPTS
# systemctl start mysqld
# echo "MySql is Start"
# UPDATE mysql.user SET authentication_string = PASSWORD('Otus2020') WHERE User = 'root' AND Host = 'localhost';