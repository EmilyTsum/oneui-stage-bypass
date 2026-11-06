#!/system/bin/sh
set_perm_recursive "$MODPATH" 0 0 0755 0644
for f in "$MODPATH/"*.sh; do set_perm "$f" 0 0 0755; done
