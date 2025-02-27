#!/bin/bash

br-srv_hostname=$1
srv_user=$2
srv_uid=$3

if (( $# < 3 )); then
	echo "Бивень, надо так:"
	echo "$0 br-srv_hostname srv_user srv_uid"
	exit 1
fi

###
echo "Меняем имя хоста, настраиваем время"
echo "$br-srv_hostname" > /etc/hostname
timedatectl set-timezone Asia/Barnaul

###
echo "Настраиваем удалённый доступ" 

echo "Authorized access only" > /etc/banner
echo "Banner /etc/banner" >> /etc/openssh/sshd_config

sed -i 's/#Port 22/Port 2024/g' /etc/openssh/sshd_config
#tEstIng thIs OnE
sed -i 's/#MaxAuthTries*$/MaxAuthTries 2/' /etc/openssh/sshd_config
echo "AllowUsers $srv_user" >> /etc/openssh/sshd_config

systemctl restart sshd

###
echo "Создаём пользователя. Пароль пишем ручками. Ибо я устал. =-="
adduser $srv_user -u $srv_uid
echo "$srv_user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
usermod -aG wheel $srv_user
passwd $srv_user



exit 0