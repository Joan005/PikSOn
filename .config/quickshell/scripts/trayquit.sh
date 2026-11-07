#!/bin/sh
#cierra del todo la aplicacion de icono de la bandeja
# uso: trayquit.sh ID (sin id, lista los iconos: id,pid y servicio)
want="$1" 
busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems 2>/dev/null | grep -o '"[^"]*"'| tr -d '"' | while read -r entry; do
	case "$entry" in
		*/*) svc=${entry%%/*}; path=/${entry#*/} ;;
		*) svc=$entry; path=/StatusNotifierItem ;;
	esac
	id=$(busctl --user get-property "$svc" "$path" org.kde.StatusNotifierItem Id 2>/dev/null | cut -d '"' -f2)
	pid=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus GetConnectionUnixProcessID s "$svc" 2>/dev/null | awk '{print$2}')
	if [ -z "$want" ]; then
		echo "id=$id pid=$pid servicio=$svc"
	elif [ "$id" = "$want" ] && [ -n "$pid" ] && [ "$pid" -gt 1 ]; then
		kill "$pid"
		sleep 2
		kill -0 "$pid" 2>/dev/null && kill -9 "$pid"
	fi
done
