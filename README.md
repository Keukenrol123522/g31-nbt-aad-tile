# NBT-AAD main-menu tile (CarLife entry) - patch for v1.9.19 (cc-pf)

Unofficial patch for [Sq00ky/Supra-iDrive6-Android-Auto](https://github.com/Sq00ky/Supra-iDrive6-Android-Auto)
(NBT-AAD), tag `cc-pf` (v1.9.19-safety, commit `e421c93`). It adds the **opt-in main-menu tile** discussed in
issues #19 and #55: the daemon registers the head unit's own CarLife device, so the HMI shows its native CarLife
entry on the home screen **and** as a source in Media/Radio, and a press on it brings Android Auto to the front.

**Status: tested on exactly one car** - BMW G31, `NBTevo_Y21432J`, ID6L UI, Samsung S26 Ultra, wireless Android Auto.
No cluster/HUD or other models tested. Use at your own risk. See *Safety* below.

## Credits

* **Sq00ky / nanaisu** - NBT-AAD itself. Everything here is a patch on top of his source and stays under his licence.
* **RRudkinp** - found the mechanism (MOST device `0x2471`, `AppState 0xCF1`, `Set 0xCE8`) and wrote the original
  patch against the old `src/ccs_input.cpp`, posted in issue #55 (`nbt-aad_main_menu_tile.zip`). This port re-implements
  that behaviour on the refactored MOST client of v1.9.x; the reverse-engineering notes in `src/car/menu_tile.cpp` are
  taken from there.
* **deathwalker80** - tested the tile on a MINI F60 and pushed for it to become an opt-in (`NBT_TILE`) upstream.
* **[Bavarian SSH](https://ssh.bavarian-aa.uk/)** - opens SSH on the head unit. You need this before anything here works.
* Toolchain: [luka-dev/qnx65-armv7-toolchain](https://github.com/luka-dev/qnx65-armv7-toolchain).

## What it does

* `NBT_TILE=1` (default **off**) turns it on, `NBT_TILE_ALWAYS=1` keeps the tile visible without a phone (testing).
* A new `car::MenuTile` registers MOST device FBlock `0x24` instance `0x71`, answers the HMI's notification requests,
  publishes `AppState` (0 = tile shown while a phone session is active, 1 = hidden), and on `Set 0xCE8` does the same
  as the iDrive "Open Android Auto" entry. Everything runs on the MOST client's DSI callback thread.
* `most::Client` gets a small optional `DeviceHook` (registered / message / tick). Without a hook the client is exactly
  as observe-only as before. This is the one place the daemon **sends** on MOST (registerDevices, processMessage,
  unregister), and only for that one device.
* `src/compat_gcc44.cpp`: two helpers that GCC 4.9 code calls but the head unit's libstdc++ 6.0.13 lacks
  (`std::__throw_out_of_range_fmt`, `__cxa_throw_bad_array_new_length`).

Apply: `git apply patches/0001-main-menu-tile.diff` in the **root** of a checkout of tag `cc-pf` (checked with
`git apply --check`). Paths in the diff start with `milestone-7/`: it adds `milestone-7/src/car/menu_tile.{hpp,cpp}` and
`milestone-7/src/compat_gcc44.cpp`, edits `src/most/{client,ids}.*`, `src/main.cpp`, `Makefile`, `CMakeLists.txt`, and sets
the build string to `v1.9.19-tile2`.

## The important lesson: test in the plugin's environment

A first build that linked `libstdc++` statically ran fine from an SSH shell but **crashed on every start by the
plugin** (`[CRASH] fatal signal 11` right after `[BluetoothManager] Initializing (DSI client ...)`), because the HMI's
`LD_PRELOAD` (the `*_X.gpp.so` graphics libs) already loads the GNU libstdc++ - two runtimes in one process. With
"Start automatically" on that is a **boot loop**. The fix is to link dynamically against the head unit's libstdc++
(`tools/build-nbt-aad-dynamic.sh`, `tools/check-syms.sh`) and to test with
`tools/test-in-hmi-env.cmd`, which reproduces the plugin's `LD_PRELOAD`.

## Safety

* Keep "Start automatically" **off** while you try a new build. Install, press Restart in the Android Auto menu, check,
  and only then switch autostart on. The plugin also skips autostart after 3 starts within 15 minutes.
* Always keep the release daemon: `tools/install-tile.cmd` moves it to `/opt/aa/nbt-aad.release-backup`;
  `tools/restore-daemon.cmd` puts it back.
* The scripts use the head unit's link-local address and need SSH opened beforehand with [Bavarian SSH](https://ssh.bavarian-aa.uk/) (closes again on every head unit reboot); they ask for the
  root password themselves, nothing is stored. The head unit's shell lacks `head`, `cmp`, `tar` etc., and PowerShell 5.1
  eats double quotes in native arguments - the scripts are written around that.

## Not included on purpose

* No BMW files (`text.db`, original images, backups) and no binaries.
* Cosmetics (own icons, renaming the "n. t. a. (ASIA)" label in `text.db`) modify head unit files and are out of scope here.
  RRudkinp's `AA-Tile.zip` in issue #55 does the label; the Android Auto logo is Google's, supply your own.

## Licence

PolyForm Noncommercial 1.0.0, see `LICENSE.md` (copied unchanged from upstream). Required notice, as in the source files:
*Copyright (c) 2026 nanaisu - NBT-AAD (https://github.com/Sq00ky/Supra-iDrive6-Android-Auto)*. Noncommercial use only.
Not affiliated with or endorsed by the NBT-AAD author, BMW or Google.

---

## Kort in het Nederlands

Onofficiële patch voor NBT-AAD v1.9.19 die de CarLife-ingang van de BMW-HMI hergebruikt als Android Auto-tegel in het
hoofdmenu en in Media/Radio. Getest op één BMW G31 (`NBTevo_Y21432J`). **Test een nieuwe build altijd met
`tools/test-in-hmi-env.cmd`** (de omgeving van de plugin), houd "Start automatically" uit tot het werkt, en bewaar de
release-daemon als terugvaloptie. Gebruik op eigen risico.
