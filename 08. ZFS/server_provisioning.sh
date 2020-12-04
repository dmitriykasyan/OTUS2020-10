sudo su -l
sudo install -y wget tree
modprobe zfs
zpool create storage raidz1 sd{b..e}
echo "#### Stage 1 ####"
zfs create -p -o compression=gzip-9 storage/folder_gzip-9
zfs create -p -o compression=zle storage/folder_zle
zfs create -p -o compression=lzjb storage/folder_lzjb
zfs create storage/folder_lz4
zfs set compression=lz4 storage/folder_lz4
wget -O War_and_Peace.txt http://www.gutenberg.org/files/2600/2600-0.txt
cp War_and_Peace.txt /storage/folder_gzip-9
cp War_and_Peace.txt /storage/folder_lz4
cp War_and_Peace.txt /storage/folder_lzjb
cp War_and_Peace.txt /storage/folder_zle
zfs list
zfs get -r compressratio storage
tree -sh /storage
echo "Stage 1 is complite"
pause 10s
echo "#### Stage 2 ####"
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg' -O otus_task2.gz
gunzip otus_task2.gz
tar -xf otus_task2
zpool import -d zpoolexport/filea
zpool import  -d filea 6554193320433390805
zpool list
zpool status -v
zfs list
ls /otus/hometask2/
zfs get -s local all otus
echo "Stage 2 is complite"
pause 20s
echo "#### Stage 3 ####"
wget --no-check-certificate 'https://drive.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG' -O otus_task3
file otus_task3
zfs receive otus/storage@task2 < otus_task3
zfs rollback otus/storage@task2
zfs list
cd /otus/storage
tar -tvf cinderella.tar |grep secret
find . -name secret_message
cat task1/file_mess/secret_message
echo "Stage 3 is complite"
pause 20s
