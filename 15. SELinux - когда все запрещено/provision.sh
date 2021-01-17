#!/bin/bash
# Подготовка стенда
sudo su -l
whoami
echo "*** Installing Nginx ***"
yum install nginx -y -q
systemctl enable nginx
systemctl start nginx
systemctl status nginx
ss -tnlp
echo "**** Prepare is Complite ****"
echo "*** Installing SELinux packages ***"
yum install setools-console policycoreutils-python policycoreutils-newrole selinux-policy-mls -y -q
sed -i 's/80/8088/g' /etc/nginx/nginx.conf
systemctl restart nginx
audit2why < /var/log/audit/audit.log
echo "**** Nginx isn\`t start on 8088 ****"
sleep 5
# Изменение порта Nginx
semanage port -l |grep http
semanage port -a -t http_port_t -p tcp 8088
semanage port -l |grep http
systemctl restart nginx
ss -tlnp |grep nginx
echo "**** Nginx is start on 8088 ****"
echo "***** Stage 1 is complite *****"
sleep 10
semanage port -d -t http_port_t -p tcp 8088
semanage port -l |grep http
systemctl restart nginx
sleep 5
# Создание модуля 
yum provides sealert
echo "*** Installing setroubleshoot-server ***"
yum install setroubleshoot-server -y -q
sealert -a /var/log/audit/audit.log
#ausearch -c 'my-nginx' --raw | audit2allow -M my-nginx ### Не заработал при провижининге
audit2allow -M my-nginx --debug < /var/log/audit/audit.log
semodule -i my-nginx.pp
semodule -l |grep my-nginx
systemctl restart nginx
systemctl status nginx
ss -tlnp |grep nginx
echo "**** Nginx is start on 8088 ****"
echo "***** Stage 2 is complite *****"
sleep 10
semodule -d my-nginx
semodule -l |grep my-nginx
systemctl restart nginx
sleep 5
# getsebool
sealert -a /var/log/audit/audit.log
getsebool -a |grep nis_enabled
setsebool -P nis_enabled 1
getsebool -a |grep nis_enabled
systemctl restart nginx
systemctl status nginx
ss -tlnp |grep nginx
echo "**** Nginx is start on 8088 ****"
echo "***** Stage 3 is complite *****"
echo "****** Finished ******"
