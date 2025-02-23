#!/bin/sh
#
SS_SERVER_IP="127.0.0.1"
SS_SERVER_PORT="1080"

add_rules() {

  ### create rule
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
  
  ### redirect other net traffic
  iptables -t nat -A SHADOWSOCKS -p tcp -j REDIRECT --to-ports $SS_SERVER_PORT
  
  ### apply the rule to OUTPUT
  iptables -t nat -A OUTPUT -p tcp -j SHADOWSOCKS
  
  ### apply the rule to transparency proxy
  iptables -t nat -A PREROUTING -p tcp -j SHADOWSOCKS

  ### save
  netfilter-persistent save
}

remove_rules() {
  ### remove transparency proxy
  iptables -t nat -D PREROUTING -p tcp -j SHADOWSOCKS 

  ### remove OUTPUT
  iptables -t nat -D OUTPUT -p tcp -j SHADOWSOCKS

  ### remove redirect
  iptables -t nat -D SHADOWSOCKS -p tcp -j REDIRECT --to-ports $SS_SERVER_PORT

  ### clear rules
  iptables -t nat -F SHADOWSOCKS

  ### remove chain
  iptables -t nat -X SHADOWSOCKS

  ### save
  netfilter-persistent save
}

show_rules() {
    iptables -t nat -L -n -v
}

usage() {
    echo "Usage: $0 {add|remove|show}"
    echo "  add    - Add Shadowsocks Rules"
    echo "  remove - Remove Shadowsocks Rules"
    echo "  show   - Show Current NAT Rules"
    exit 1
}

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
