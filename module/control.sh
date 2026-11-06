#!/system/bin/sh
set -eu
M=${0%/*}
STATE=/data/adb/oneui-stage-bypass
BB=
for candidate in /data/adb/ksu/bin/busybox /data/adb/magisk/busybox /data/adb/ap/bin/busybox; do
 [ ! -x "$candidate" ] || { BB=$candidate; break; }
done
[ -n "$BB" ] || { echo 'Root-manager BusyBox required'; exit 1; }
[ "$(id -u)" = 0 ] || { echo 'root required'; exit 1; }
if [ "${ONEUI_STAGE_INIT_NS:-}" != 1 ]; then
 export ONEUI_STAGE_INIT_NS=1
 exec "$BB" nsenter -t 1 -m -- /system/bin/sh "$0" "$@"
fi
find_target() {
 TARGET=; count=0
 for p in /system/etc/stage_policy.conf /vendor/etc/stage_policy.conf /odm/etc/stage_policy.conf /product/etc/stage_policy.conf /system_ext/etc/stage_policy.conf; do
  [ ! -f "$p" ] || { TARGET=$p; count=$((count+1)); }
 done
 [ "$count" = 1 ] || { echo "Expected exactly one stage_policy.conf; found $count"; return 1; }
}
file_id() { "$BB" stat -c '%d:%i' "$1"; }
ours() { [ -f "$STATE/patched.conf" ] && [ "$(file_id "$TARGET")" = "$(file_id "$STATE/patched.conf")" ]; }
find_target
case "${1:-status}" in
 status)
  enabled=ON; [ ! -e "$M/disable" ] && [ ! -e "$M/remove" ] || enabled=OFF
  live=UNMANAGED; if ours; then live=MOUNTED; fi
  echo "startup=$enabled runtime=$live target=$TARGET"; exit 0;;
 preview) "$BB" awk -f "$M/patch.awk" "$TARGET"; exit $?;;
 apply|on|off|detach) ;;
 *) echo 'usage: control.sh status|preview|on|off'; exit 2;;
esac
umask 077; mkdir -p "$STATE"
if ! mkdir "$STATE/lock" 2>/dev/null; then
 oldboot=$(cat "$STATE/lock/boot" 2>/dev/null || true)
 if [ -n "$oldboot" ] && [ "$oldboot" != "$(cat /proc/sys/kernel/random/boot_id)" ]; then
  rm -f "$STATE/lock/boot"; rmdir "$STATE/lock"; mkdir "$STATE/lock"
 else echo 'Another operation or stale lock exists; inspect it first'; exit 1; fi
fi
cat /proc/sys/kernel/random/boot_id > "$STATE/lock/boot"
trap 'rm -f "$STATE/lock/boot"; rmdir "$STATE/lock"' EXIT
case "$1" in
 off|detach)
  [ "$1" != off ] || touch "$M/disable"
  if ours; then "$BB" umount -l "$TARGET"; fi
  echo 'Mount detached. Existing audio processes may keep their previous configuration.'
  exit 0;;
 on) rm -f "$M/disable";;
 apply) [ ! -e "$M/disable" ] && [ ! -e "$M/remove" ] || exit 0;;
esac
[ ! -e "$M/remove" ] || exit 1
if ours; then echo 'Already mounted'; exit 0; fi
# Avoid stacking with the earlier device-specific module.
OLD=/data/adb/modules/s25_stock_fx_bypass
if [ -d "$OLD" ] && [ ! -e "$OLD/disable" ] && [ ! -e "$OLD/remove" ]; then
 echo 'Disable and detach s25_stock_fx_bypass first'; exit 1
fi
# Inspect the mount backing the opened file. Hidden mounts under a later
# parent mount can retain the same pathname in mountinfo.
exec 9< "$TARGET"
mount_id=$("$BB" awk '$1=="mnt_id:" {print $2}' /proc/$$/fdinfo/9)
exec 9<&-
[ -n "$mount_id" ] || { echo 'Cannot identify active mount'; exit 1; }
if "$BB" awk -v id="$mount_id" -v p="$TARGET" '$1==id && $5==p {found=1} END {exit !found}' /proc/self/mountinfo; then
 echo 'Another mount already covers the target'; exit 1
fi
TMP="$STATE/patched.new"
if ! "$BB" awk -f "$M/patch.awk" "$TARGET" > "$TMP" 2> "$STATE/patch.log"; then
 rm -f "$TMP"; cat "$STATE/patch.log"; exit 1
fi
if cmp -s "$TARGET" "$TMP"; then rm -f "$TMP"; echo 'No supported effect references to remove'; exit 1; fi
cp "$TARGET" "$STATE/original.conf"
mv "$TMP" "$STATE/patched.conf"
chmod 644 "$STATE/patched.conf"
chown 0:0 "$STATE/patched.conf"
"$BB" chcon --reference="$TARGET" "$STATE/patched.conf"
"$BB" mount -o bind "$STATE/patched.conf" "$TARGET"
ours || { echo 'Mount verification failed'; exit 1; }
echo 'Configuration mounted. Reboot manually to reload the audio stack; no restart was performed.'
