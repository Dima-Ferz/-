#!/bin/bash

br-rtr_int1=
br-rtr_int2=
br-rtr_ip_int1=
br-rtr_ip_int2=

add2=`echo $br-rtr_int2 | awk -F/ '{ print $1 }' | sed 's/.$/0/'`
mask2=`echo $br-rtr_int2 | awk -F/ '{ print $2 }'`
net_int2=$addr2/$mask2

hq-rtr_ip_int1=
br-rtr_ip_r1=
br-rtr_iptun=
br-rtr_hostname=

rtr_user=
rtr_uid=


###
echo "Пинаем интерфейсы"
mkdir -p /etc/net/ifaces/$br-rtr_int2 && touch /etc/net/ifaces/$br-rtr_int1/options
mkdir -p /etc/net/ifaces/tun1 && touch /etc/net/ifaces/tun1/options
 
echo "BOOTPROTO=static
TYPE=eth
DISABLED=no
CONFIG_IPV4=yes
" > /etc/net/ifaces/$br-rtr_int2/options

echo "TYPE=iptun
TUNTYPE=gre
TUNLOCAL=$br-rtr_ip_int1
TUNREMOTE=$hq-rtr_ip_int1
TUNOPTIONS='ttl 64'
HOST=$br-rtr_int1
" > /etc/net/ifaces/tun1/options

echo "$br-rtr_ip_int2" > /etc/net/ifaces/$br-rtr_int2/ipv4address
echo "$br-rtr_iptun" > /etc/net/ifaces/tun1/ipv4address

systemctl restart network && ping -c4 77.88.8.8

###
echo "Время + хост"
echo "$br-rtr_hostname" > /etc/hostname
timedatectl set-timezone Asia/Novosibirsk

###
echo "Настраиваем nftables"
sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1" /etc/net/sysctl.conf

apt-get update && apt-get install -y nftables && systemctl enable --now nftables

nft add table ip nat
nft add chain ip nat postrouting ‘{ type nat hook postrouting priority 0; }’
nft add rule ip nat postrouting ip saddr $net_int2 oifname "$br-rtr_int1" counter masquerade

nft list ruleset | tail -n6 | tee -a /etc/nftables/nftables.nft
systemctl restart nftables && systemctl restart network

###
echo "Создаём пользователя. Пароль пишем ручками. Ибо я устал. =-="
adduser $rtr_user -u $rtr_uid
echo "$rtr_user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
usermod -aG wheel $rtr_user
passwd $rtr_user

###
echo "Настроили интерфейсы, nftables, время, создали пользователя, поменяли имя хоста"
ping -c4 77.88.8.8

exit 0