sudo su -l
yum install autofs -y
cat >> /etc/auto.master << EOF_auto.master
##### NFS SHARE ####
/mnt    /etc/auto.nfs
EOF_auto.master
echo "upload  -rw,vers=3,proto=udp    192.168.50.10:/srv/storage" > /etc/auto.nfs
systemctl enable autofs
systemctl start autofs
systemctl status autofs
sleep 5s 
su vagrant
dd if=/dev/zero of=/mnt/upload/file_vagrant bs=1M count=15
ls -lah /mnt/upload
mount | tail -n3
echo "======Autofs is run ======"
sleep 5s
echo "Well done!!!"
