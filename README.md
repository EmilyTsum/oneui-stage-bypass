# OneUI Stage Bypass

Experimental, console-only root module for Samsung `stage_policy.conf`.
Removes selected Dolby, SoundAlive Plus and AdaptSound assignments from
`prefx`, `postfx`, `integ-pre` and `integ-post`. Other effects, including
SoundBooster and volume-monitor assignments, are retained.

This is **not** a universal Samsung audio bypass, a latency fix, or a DSP.
It does not change HAL routing, fast/offload eligibility, global effects,
LightningDSP settings or SoundAssistant. Retaining protection assignments
is not proof of speaker safety across devices.

## Compatibility and evidence

- Parser tested against one SM-S931Z Android 17 configuration and on its
  KernelSU BusyBox. Output exactly matched the existing device-specific
  bypass (71 removed references).
- Seven synthetic parser tests cover preservation, malformed syntax and
  idempotence. No proprietary configuration is distributed.
- Generic-module activation, OFF restoring the original file, ON restoring
  the patched file, and repeated apply were validated on that phone.
  Active mounts are identified by the opened file's mount ID; hidden legacy
  mounts under an overmounted parent do not cause false conflicts.
  Boot lifecycle, other devices, Magisk/APatch and new audible tests remain
  unverified. The audio stack was not restarted during migration.
- Requires a root manager with BusyBox at one of the paths in `control.sh`,
  `nsenter`, `chcon --reference`, and permission to bind mount in init's
  mount namespace. This module grants no SELinux permissions.

## Install and operate

Build with `python3 build.py`; install the resulting ZIP through your root
manager. Remove conflicting stage-policy modules first, then manually
reboot to clear old mounts. Do not install both this and a legacy bypass.
Unknown/multiple configuration paths and existing file mounts are refused.
The parser accepts only its known assignment syntax, not every Samsung
configuration format. Inspect generated output before relying on it.

In an authorized root shell:

```sh
sh /data/adb/modules/oneui_stage_bypass/control.sh status
sh /data/adb/modules/oneui_stage_bypass/control.sh preview
sh /data/adb/modules/oneui_stage_bypass/control.sh on
sh /data/adb/modules/oneui_stage_bypass/control.sh off
```

`on`/`off` change startup configuration and attach/detach our own file mount.
They do not restart audio processes. A manual reboot is needed to reliably
reload the audio configuration. With temporary root, startup depends on
that root solution's late-load support. Nothing triggers a reboot for you.

Private on-device backup and generated configuration:
`/data/adb/oneui-stage-bypass/`. No device files are uploaded.
If activation fails, inspect `last.log` and `patch.log`; do not remove
unknown mounts. A same-boot stale lock deliberately blocks another write.

## Restore

Run `off`, disable/remove the module in the root manager, and reboot
manually. The underlying system file is never written. Existing processes
can retain their loaded configuration until restarted. Keep a known-good
root-manager recovery method available when testing an unsupported phone.

## Develop

```sh
python3 -m unittest discover -s tests -v
python3 build.py
```

Not affiliated with Samsung. Contributions should use synthetic fixtures;
do not submit device dumps, purchased fonts, credentials or private data.
