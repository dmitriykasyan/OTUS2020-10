mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh
echo "export PS1='\u@\[\e[1;36m\]\h\[\e[m\] \W\\$ '" >> .bashrc
echo "export PS1='\u@\[\e[1;32m\]\h\[\e[m\] \W\\$ '" >> /root/.bashrc
yum install epel-release bash-completion -y
#### PAM
sudo useradd day && \
sudo useradd night && \
sudo useradd friday
echo "Otus2019"|sudo passwd --stdin day &&\
echo "Otus2019" | sudo passwd --stdin night &&\
echo "Otus2019" | sudo passwd --stdin friday
sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config \
&& systemctl restart sshd.service

cat >> /etc/security/time.conf << EOF
*;*;day;Al0800-2000
*;*;night;!Al0800-2000
*;*;friday;Fr0000-2400
EOF
sed -i '/account    required     pam_nologin.so/ a account    required     pam_time.so' /etc/pam.d/sshd

cat <<'EOF' >> /usr/local/bin/test_login.sh
#!/bin/bash
if [ $PAM_USER = "friday" ]; then
  if [ $(date +%a) = "Fri" ]; then
    exit 0
  else
    exit 1
  fi
fi
hour=$(date +%H)
is_day_hours=$(($(test $hour -ge 8; echo $?)+$(test $hour -lt 20; echo $?)))
if [ $PAM_USER = "day" ]; then
  if [ $is_day_hours -eq 0 ]; then
    exit 0
  else
    exit 1
  fi
fi
if [ $PAM_USER = "night" ]; then
  if [ $is_day_hours -eq 1 ]; then
    exit 0
  else
    exit 1
  fi
fi

cat >> /etc/security/time.conf << EOF
*;*;day;Al0800-2000
*;*;night;!Al0800-2000
*;*;friday;Fr0000-2400
EOF

chmod +x /usr/local/bin/test_login.sh
sed -i 's/account    required     pam_time.so/# account    required     pam_time.so/' /etc/pam.d/sshd
sed -i '/account    required     pam_time.so/ a account    required     pam_exec.so /usr/local/bin/test_login.sh' /etc/pam.d/sshd

# # ##### Group limits
# useradd -m -s /bin/bash user1
# useradd -m -s /bin/bash user2
# echo "Otus2020" | sudo passwd --stdin user1 &&\
# echo "Otus2020" | sudo passwd --stdin user2
# groupadd admin && \
# gpasswd -a user1 admin && \
# gpasswd -a user2 admin
#
#
# cat >> /etc/security/group.conf << EOF
# *;*;*;Wd0900-2000;*
# *;*;*;Al0000-2400;admin
# EOF
