#!/bin/bash


hq_rtr_int1=$1
hq_rtr_int2=$2
hq_rtr_int3=$3
hq_rtr_ip_int2=$4
hq_rtr_ip_int3=$5
mgmt_ip=$6
vid_srv=$7
vid_cli=$8
vid_mgnt=$9

addr2=`echo $br-rtr_int2 | awk -F/ '{ print $1 }' | sed 's/.$/0/'`
mask2=`echo $br-rtr_int2 | awk -F/ '{ print $2 }'`
net_int2=$addr2/$mask2

hq_rtr_iptun=$10
br_rtr_ip_int1=$11
hq_rtr_hostname=$12
rtr_user=$13
rtr_uid=$14


if (( $# < 14 )); then
	echo "Бивень, надо так:"
	echo "$0 interface1 int2(srv) int3(cli) ip_addr_int2 ip_addr_int3 managment_ip vid-srv vid-cli vid-managment iptun_addr br-ip-int1 hostname user uid"
	exit 1
fi

###
echo "Пинаем интерфейсы"
mkdir -p /etc/net/ifaces/$hq_rtr_int2
mkdir -p /etc/net/ifaces/$hq_rtr_int3
mkdir -p /etc/net/ifaces/$hq_rtr_int2.$vid_srv
mkdir -p /etc/net/ifaces/$hq_rtr_int2.$vid_cli
mkdir -p /etc/net/ifaces/$hq_rtr_int2.$vid_mgnt
mkdir -p /etc/net/ifaces/tun1

echo "BOOTPROTO=static
TYPE=eth
DISABLED=no
CONFIG_IPV4=yes
" > /etc/net/ifaces/$hq_rtr_int2/options
cp /etc/net/ifaces/$hq_rtr_int2/options /etc/net/ifaces/$hq_rtr_int3/options

echo "TYPE=vlan
HOST=$hq_rtr_int2
VID=$vid_srv
DISABLED=no
BOOTPROTO=static
ONBOOT=yes
CONFIG_WIRELESS=no
" > /etc/net/ifaces/$hq_rtr_int2.$vid_srv/options

cp /etc/net/ifaces/$hq_rtr_int2.$vid_srv/options /etc/net/ifaces/$hq_rtr_int2.$vid_cli/options
sed -i 's/VID=$vid_srv/VID=$vid_cli/' /etc/net/ifaces/$hq_rtr_int2.$vid_cli/options

cp /etc/net/ifaces/$hq_rtr_int2.$vid_srv/options /etc/net/ifaces/$hq_rtr_int2.$vid_mgnt/options
sed -i 's/VID=$vid_srv/VID=$vid_mgnt/' /etc/net/ifaces/$hq_rtr_int2.$vid_mgnt/options

echo "TYPE=iptun
TUNTYPE=gre
TUNLOCAL=`cat /etc/net/$hq_rtr_int1/ipv4address`
TUNREMOTE=$br_rtr_ip_int1
TUNOPTIONS='ttl 64'
HOST=$hq_rtr_int1
" > /etc/net/ifaces/tun1/options

echo "$hq_rtr_ip_int2" > /etc/net/ifaces/$hq_rtr_int2.$vid_srv/ipv4address
echo "$hq_rtr_ip_int3" > /etc/net/ifaces/$hq_rtr_int2.$vid_cli/ipv4address
echo "$mgmt_ip" > /etc/net/ifaces/$hq_rtr_int2.$vid_mgnt/ipv4address
echo "$hq_rtr_iptun" > /etc/net/ifaces/tun1/ipv4address

systemctl restart network

###
echo "Время + хост"
echo "$hq_rtr_hostname" > /etc/hostname

apt-get update && apt-get install -y tzdata && timedatectl set-timezone Asia/Novosibirsk

###
echo "Настраиваем nftables"
sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/" /etc/net/sysctl.conf

apt-get update && apt-get install -y nftables && systemctl enable --now nftables

nft add table ip nat
nft add chain ip nat postrouting '{ type nat hook postrouting priority 0; }'
nft add rule ip nat postrouting ip saddr $net_int2 oifname "$hq_rtr_int1" counter masquerade

nft list ruleset | tail -n7 | tee -a /etc/nftables/nftables.nft
systemctl restart nftables && systemctl restart network

###
echo "Создаём пользователя. Пароль пишем ручками. Ибо я устал. =-="
adduser $rtr_user -u $rtr_uid
echo "$rtr_user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
usermod -aG wheel $rtr_user
passwd $rtr_user

###
echo "Настроили интерфейсы, nftables, время, создали пользователя, поменяли имя хоста"
nft list ruleset && ping -c4 77.88.8.8

exit 0
