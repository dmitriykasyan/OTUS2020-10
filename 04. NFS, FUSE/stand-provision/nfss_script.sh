sudo su -l
### firewall-provisioning ###
systemctl start firewalld
systemctl status firewalld
sleep 5s
firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --permanent --zone=public --add-service=nfs3
firewall-cmd --permanent --zone=public --add-service=mountd
firewall-cmd --permanent --zone=public --add-service=rpc-bind
firewall-cmd --permanent --list-all
systemctl reload firewalld
#systemctl status firewalld
sleep 5s
echo "======Firewall is run======"
### nfs-provisioninig ###
mkdir /srv/storage
chown -R nfsnobody:nfsnobody /srv/storage/
chmod -R 777 /srv/storage/
ls -lah  /srv/storage/
echo "/srv/storage    192.168.50.0/24(rw,sync,root_squash)" > /etc/exports
systemctl enable rpcbind
systemctl enable nfs-server
systemctl start rpcbind nfs-server
exportfs -v
dd if=/dev/zero of=/srv/storage/file1 bs=1M count=10
echo "======NFS server is run======"
