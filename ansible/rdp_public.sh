#!/bin/bash
#

help () {
  echo "$0 [on/off]"
}

if [ $# -ne 1 ]; then
  help
  exit 0
fi

if [ "$1" == "on" ]; then
  iptables -I FORWARD -p tcp -d 192.168.3.112 --dport 3389 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
  iptables -t nat -A PREROUTING -p tcp -i br0 --dport 14999 -j DNAT --to-destination 192.168.3.112:3389
  echo "Public RDP access enabled"
  exit 0
elif [ "$1" == "off" ]; then
  iptables -D FORWARD -p tcp -d 192.168.3.112 --dport 3389 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
  iptables -t nat -D PREROUTING -p tcp -i br0 --dport 14999 -j DNAT --to-destination 192.168.3.112:3389
  echo "Public RDP access disabled"
  exit 0
fi

help
exit 0
