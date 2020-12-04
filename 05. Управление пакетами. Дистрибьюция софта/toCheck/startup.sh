# This is the startup.sh file called by Vagrantfile
           mkdir -p ~root/.ssh
           cp ~vagrant/.ssh/auth* ~root/.ssh
           yum install epel-release -y -q
           echo "export PS1='\u@\[\e[1;36m\]\h\[\e[m\] \W\\$ '" >> .bashrc
           sudo su -l
           echo "export PS1='\u@\[\e[1;32m\]\h\[\e[m\] \W\\$ '" >> /root/.bashrc
           sudo su vagrant
# Install tools for building rpm
           yum install tree yum-utils mc wget gcc vim git \
           rpmdevtools rpm-build -y -q
           yum install redhat-lsb-core wget -y -q
# Install tools for building woth mock and make prepares
           yum install mock -y -q
           usermod -a -G mock root
# Install tools for creating your own REPO
           yum install createrepo -y -q
# Install docker-ce
           # sudo yum install yum-utils links \
           # device-mapper-persistent-data \
           # lvm2 -y -q
           # sudo yum-config-manager \
           # --add-repo \
           # https://download.docker.com/linux/centos/docker-ce.repo
           # yum install docker-ce -y  \
           # docker-compose -y
           # systemctl start docker
           # systemctl start nginx
           # docker run hello-world
#Provisioning
echo "Start Stage 1 ---Build NGINX 1.14 with OpenSSL"
           sudo su -l
           wget -P /root https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
           rpm -i /root/nginx-1.14.1-1.el7_4.ngx.src.rpm
           wget -P /root https://www.openssl.org/source/latest.tar.gz
           tar -C /root -xvf /root/latest.tar.gz
           yum-builddep /root/rpmbuild/SPECS/nginx.spec -y
           sed -i 's/\-\-with\-debug/\-\-with\-openssl=\/root\/openssl\-1\.1\.1g/' /root/rpmbuild/SPECS/nginx.spec
           rpmbuild -bb /root/rpmbuild/SPECS/nginx.spec
           yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
           systemctl start nginx.service
           systemctl status nginx
echo "Stage 1 is complite"

echo "Start Stage 2 --Creating local repo"
           mkdir /usr/share/nginx/html/repo
           cp /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo/
           wget \
           http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm\
            -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm
           createrepo /usr/share/nginx/html/repo/
           sed -i '/index  index.html index.htm;/ a autoindex on;' /etc/nginx/conf.d/default.conf
           nginx -t
           nginx -s reload
cat << EOF > /etc/yum.repos.d/otus.repo
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
           yum-config-manager --disable epel
           yum-config-manager --enable otus
           yum reinstall nginx -y
           yum-config-manager --enable epel
echo "Stage 2 is complite"
echo "Stand is ready!"
