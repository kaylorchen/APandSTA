#!/bin/bash
PHY=phy0
DEV=Reebotic_AP
iw phy ${PHY} interface add ${DEV} type managed addr 00:30:1a:42:82:2f
ip link set dev ${DEV} up

# Config Wireless
ifconfig $DEV up
ifconfig $DEV 172.16.1.1/24
ifconfig $DEV mtu 1500

# Configure dnsmasq
cat > /etc/dnsmasq.conf << EOF
dhcp-range=172.16.1.100,172.16.1.150,255.255.255.0,24h
port=0
dhcp-option=option:dns-server,114.114.114.114
interface=${DEV}
EOF

service dnsmasq stop
service dnsmasq start


channel=$(iw dev wlan0 info | grep channel | awk -F " " '{print $2}')
if [ ! -n "${channel}" ]; then
    echo "channle is null"
else
    echo channel is ${channel}
    sed -i  '/^channel=/cchannel='${channel} hostapd.conf
fi


killall hostapd
hostapd -B ./hostapd.conf
echo "1"  > /proc/sys/net/ipv4/ip_forward
iptables -P FORWARD ACCEPT
# NAT with iptables
iptables -t nat -A POSTROUTING -s 172.16.1.1/24 -j MASQUERADE