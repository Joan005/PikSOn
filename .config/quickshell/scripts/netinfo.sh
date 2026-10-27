#!/bin/sh
# Imprime clave=valor con el detalle de la xonexion activa ethernet o wifi
dev=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$3=="connected" && ($2=="ethernet" || $2=="wifi") {print $1; exit}')
if [ -z "$dev" ]; then
	echo "estado=none"
	exit 0

fi
speed=$(cat "/sys/class/net/$dev/speed" 2>/dev/null)
case "$speed" in
	''|-*) speed="-" ;;
	*) speed="$speed Mb/s" ;;
esac
echo "estado=ok"
echo "dispositivo=$dev"
echo "tipo=$(nmcli -g GENERAL.TYPE device show "$dev")"
echo "conexion=$(nmcli -g GENERAL.CONNECTION device show "$dev")"
echo "ip=$(nmcli -g IP4.ADDRESS device show "$dev" | cut -d'|' -f1)"
echo "puerta=$(nmcli -g IP4.GATEWAY device show "$dev")"
echo "dns=$(nmcli -g IP4.DNS device show "$dev" | tr '|' ' ')"
echo "mac=$(nmcli -g GENERAL.HWADDR device show "$dev" | tr -d '\\')"
echo "velocidad=$speed"
