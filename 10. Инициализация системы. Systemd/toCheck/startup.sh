# This is the startup.sh file called by Vagrantfile
mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh
yum install epel-release -y

echo "---Part 1 Start!!!---"

sudo su -l

cat << EOF > /etc/sysconfig/watchlog
# Configuration file for my watchdog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
EOF

cat << EOF > /var/log/watchlog.log
"ALERT"
"NOTYFY"
EOF

cat << EOF > /opt/watchlog.sh
#! /bin/bash

WORD=$1
LOG=$2
DATE='date'

if grep $WORD $LOG &> /dev/null
then
   logger "$DATE: I found word, Master!"
else
   exit 0
fi
EOF

chmod +x /opt/watchlog.sh

cat << EOF > /etc/systemd/system/watchlog.service
[Unit]
  Description=My watchlog service
[Service]
  Type=oneshot
  EnvironmentFile=/etc/sysconfig/watchlog
  ExecStart=/opt/watchlog.sh $WORD $LOG
EOF

cat << EOF > /etc/systemd/system/watchlog.timer
[Unit]
  Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
  OnUnitActiveSec=30
  Unit=watchlog.service
[Install]
  WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start watchlog.service

echo "---Part 1 Complited!!!---"
echo "---Part 2 Start!!!---"
yum install spawn-fcgi php php-cli mod_fcgid httpd -y

sed -i 's/#SOCKET/SOCKET/; s/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi

cat << EOF > /etc/systemd/system/spawn-fcgi.service
[Unit]
  Description=Spawn-fcgi startup service by Otus
  After=network.target
[Service]
  Type=simple
  PIDFile=/var/run/spawn-fcgi.pid
  EnvironmentFile=/etc/sysconfig/spawn-fcgi
  ExecStart=/usr/bin/spawn-fcgi -n \$OPTIONS
  KillMode=process
[Install]
  WantedBy=multi-user.target
EOF
systemctl daemon-reload

echo "---Part 2 Complited!!!---"
echo "---Part 3 Start!!!---"
# cp /usr/lib/systemd/system/httpd.service /etc/systemd/system/httpd.service

cat << EOF > /etc/systemd/system/httpd@.service
[Unit]
  Description=The Apache HTTP Server
  After=network.target remote-fs.target nss-lookup.target
  Documentation=man:httpd(8)
  Documentation=man:apachectl(8)

[Service]
  Type=notify
  EnvironmentFile=/etc/sysconfig/httpd-%i
  ExecStart=/usr/sbin/httpd \$OPTIONS -DFOREGROUND
  ExecReload=/usr/sbin/httpd \$OPTIONS -k graceful
  ExecStop=/bin/kill -WINCH \${MAINPID}
  # We want systemd to give httpd some time to finish gracefully, but still want
  # it to kill httpd after TimeoutStopSec if something went wrong during the
  # graceful stop. Normally, Systemd sends SIGTERM signal right after the
  # ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
  # httpd time to finish.
  KillSignal=SIGCONT
  PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start httpd

cp /etc/sysconfig/httpd /etc/sysconfig/httpd-first
sed -i 's/#OPTIONS=/OPTIONS=-f conf\/first.conf/' /etc/sysconfig/httpd-first

cp /etc/sysconfig/httpd /etc/sysconfig/httpd-second
sed -i 's/#OPTIONS=/OPTIONS=-f conf\/second.conf/' /etc/sysconfig/httpd-second

cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
sed -i 's/Listen 80/Listen 8118/; /ServerRoot/a PidFile /var/run/httpd-first.pid' /etc/httpd/conf/first.conf

cp /etc/httpd/conf/first.conf /etc/httpd/conf/second.conf
sed -i 's/Listen 8118/Listen 8080/; s/PidFile \/var\/run\/httpd-first.pid/PidFile \/var\/run\/httpd-second.pid/' /etc/httpd/conf/second.conf

echo "---Part 3 Start!!!---"
