#!/bin/bash

cd /opt
wget https://github.com/prometheus/prometheus/releases/download/v2.24.1/prometheus-2.24.1.linux-amd64.tar.gz
tar xvfz prometheus-2.24.1.linux-amd64.tar.gz
rm -f prometheus-2.24.1.linux-amd64.tar.gz
ls -la

yum install ntp ntpdate
timedatectl set-ntp true
timedatectl status
./prometheus --config.file=prometheus.yml

# copy prometheus app
useradd --no-create-home --shell /bin/false prometheus
mkdir /etc/prometheus
mkdir /var/lib/prometheus
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus
cp prometheus /usr/local/bin/
cp promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool
cp -r consoles /etc/prometheus/
cp -r console_libraries/ /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus/console
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries/
cp prometheus.yml /etc/prometheus/
chown prometheus:prometheus /etc/prometheus/prometheus.yml

