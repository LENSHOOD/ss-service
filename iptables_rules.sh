#!/bin/bash

SS_LOCAL_IP="127.0.0.1"
SS_LOCAL_PORT="1080"
SS_SERVER_IP=""

add_rules() {
  ### clear existing rules to aviod duplicate
  iptables -t nat -F SHADOWSOCKS 2>/dev/null
  iptables -t mangle -F SHADOWSOCKS_UDP 2>/dev/null
  iptables -t nat -X SHADOWSOCKS 2>/dev/null
  iptables -t mangle -X SHADOWSOCKS_UDP 2>/dev/null

  ### create tcp rule
  iptables -t nat -N SHADOWSOCKS
  
  ### ignore local net
  iptables -t nat -A SHADOWSOCKS -d 0.0.0.0/8 -j RETURN
  iptables -t nat -A SHADOWSOCKS -d 10.0.0.0/8 -j RETURN
  iptables -t nat -A SHADOWSOCKS -d 127.0.0.0/8 -j RETURN
  iptables -t nat -A SHADOWSOCKS -d 169.254.0.0/16 -j RETURN
  iptables -t nat -A SHADOWSOCKS -d 172.16.0.0/12 -j RETURN
  iptables -t nat -A SHADOWSOCKS -d 192.168.0.0/16 -j RETURN
  iptables -t nat -A SHADOWSOCKS -d 224.0.0.0/4 -j RETURN
  iptables -t nat -A SHADOWSOCKS -d 240.0.0.0/4 -j RETURN
  iptables -t nat -A SHADOWSOCKS -d $SS_SERVER_IP -j RETURN

  ### redirect other net traffic
  iptables -t nat -A SHADOWSOCKS -p tcp -j REDIRECT --to-ports $SS_LOCAL_PORT
  
  ### apply the rule to OUTPUT
  iptables -t nat -A OUTPUT -p tcp -j SHADOWSOCKS
  
  ### apply the rule to prerouting
  iptables -t nat -A PREROUTING -p tcp -j SHADOWSOCKS

  ### create udp rule
  iptables -t mangle -N SHADOWSOCKS_UDP

  # ignore local net
  iptables -t mangle -A SHADOWSOCKS_UDP -d 0.0.0.0/8 -j RETURN
  iptables -t mangle -A SHADOWSOCKS_UDP -d 10.0.0.0/8 -j RETURN
  iptables -t mangle -A SHADOWSOCKS_UDP -d 127.0.0.0/8 -j RETURN
  iptables -t mangle -A SHADOWSOCKS_UDP -d 169.254.0.0/16 -j RETURN
  iptables -t mangle -A SHADOWSOCKS_UDP -d 172.16.0.0/12 -j RETURN
  iptables -t mangle -A SHADOWSOCKS_UDP -d 192.168.0.0/16 -j RETURN
  iptables -t mangle -A SHADOWSOCKS_UDP -d 224.0.0.0/4 -j RETURN
  iptables -t mangle -A SHADOWSOCKS_UDP -d 240.0.0.0/4 -j RETURN
  iptables -t mangle -A SHADOWSOCKS_UDP -d $SS_SERVER_IP -j RETURN

  ### tproxy other net traffic 
  iptables -t mangle -A SHADOWSOCKS_UDP -p udp -j TPROXY --on-ip $SS_LOCAL_IP --on-port $SS_LOCAL_PORT --tproxy-mark 0x01/0x01

  ### set route rule, make sure udp could send back
  ip rule add fwmark 0x01 lookup 100
  ip route add local default dev lo table 100

  ### apply the rule to prerouting
  iptables -t mangle -A PREROUTING -p udp -j SHADOWSOCKS_UDP

  ### save
  netfilter-persistent save
}

remove_rules() {
  ### remove tcp
  iptables -t nat -D PREROUTING -p tcp -j SHADOWSOCKS 
  iptables -t nat -D OUTPUT -p tcp -j SHADOWSOCKS
  iptables -t nat -F SHADOWSOCKS 2>/dev/null
  iptables -t nat -X SHADOWSOCKS 2>/dev/null

  ### remove udp
  iptables -t mangle -D PREROUTING -p udp -j SHADOWSOCKS_UDP 2>/dev/null
  iptables -t mangle -F SHADOWSOCKS_UDP 2>/dev/null
  iptables -t mangle -X SHADOWSOCKS_UDP 2>/dev/null

  ### remove udp routing rule
  ip rule del fwmark 0x01 lookup 100 2>/dev/null
  ip route del local default dev lo table 100 2>/dev/null

  ### save
  netfilter-persistent save
}

show_rules() {
  echo "Current NAT rules:"
  iptables -t nat -L -n -v
  echo ""
  echo "Current MANGLE rules:"
  iptables -t mangle -L -n -v
  echo ""
  echo "Current IP rules:"
  ip rule show
  echo ""
  echo "Current IP route table:"
  ip route show table 100
  echo ""
  echo "Current Env:"
  echo "SS_LOCAL_IP is $SS_LOCAL_IP"
  echo "SS_LOCAL_PORT is $SS_LOCAL_PORT"
  echo "SS_SERVER_IP is $SS_SERVER_IP"
}

usage() {
    echo "Usage: $0 {add|remove|show} {path to env file}"
    echo "  add    - Add Shadowsocks Rules"
    echo "  remove - Remove Shadowsocks Rules"
    echo "  show   - Show Current NAT Rules"
    exit 1
}

if [ -f "$2" ]; then
  set -o allexport
  source $2
  set +o allexport
else
  echo "$2: file not found"
  exit 1
fi

case "$1" in
    add)
        add_rules
        ;;
    remove)
        remove_rules
        ;;
    show)
        show_rules
        ;;
    *)
        usage
        ;;
esac

exit 0
