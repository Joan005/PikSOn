#!/bin/sh
#imprime: tipo|dispositivo|ip (o "none" si no hay conexion)
dev=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$3=="connected" &&
($2=="ethernet" || $2=="wifi") {print $1; exit}')
if [ -z "$dev" ]; then
	echo "none"
	exit 0
fi
tipo=$(nmcli -g GENERAL.TYPE device show "$dev")
ip=$(nmcli -g IP4.ADDRESS device show "$dev" | cut -d'|' -f1)
echo "$tipo|$dev|$ip"


