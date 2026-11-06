#!/system/bin/sh
M=${0%/*}
sh "$M/control.sh" apply > "$M/last.log" 2>&1
