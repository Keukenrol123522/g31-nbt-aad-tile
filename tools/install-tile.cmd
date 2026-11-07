@echo off
rem Install a tested build as /opt/aa/nbt-aad, with backups. Run test-in-hmi-env.cmd first!
rem
rem Usage:  install-tile.cmd path\to\nbt-aad-build expected-size-of-current-nbt-aad
rem   e.g.  install-tile.cmd nbt-aad-tile2 732026      (732026 = size of the v1.9.19 release daemon)
rem Does: refuses if the current daemon is not the one you named by size, stops the daemon, moves it to
rem       /opt/aa/nbt-aad.release-backup, puts the new build in place, backs up nbt-aad.env to nbt-aad.env.before-tile
rem       and adds NBT_TILE=1.
rem Rollback: see restore-daemon.cmd. Keep "Start automatically" OFF until you have started it once from the menu.
set BIN=%~1
set CUR=%~2
if "%BIN%"=="" (echo usage: install-tile.cmd build current-size & exit /b 1)
if "%CUR%"=="" (echo usage: install-tile.cmd build current-size & exit /b 1)
for %%F in ("%BIN%") do set SIZE=%%~zF
set O=-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa -o MACs=+hmac-sha1,hmac-md5 -o KexAlgorithms=+diffie-hellman-group14-sha1,diffie-hellman-group1-sha1,diffie-hellman-group-exchange-sha1 -o Ciphers=+aes128-cbc,aes256-cbc,3des-cbc -o ConnectTimeout=5
echo === installing %BIN% (%SIZE% bytes) - type the head unit password ===
ssh %O% root@169.254.199.99 "on -f /net/hu-omap/ /bin/sh -c 'mount -o remount rw /net/hu-omap/fs/sda0 || exit 1; cat > /opt/aa/nbt-aad.new; ls -l /opt/aa/nbt-aad.new | grep -q %SIZE% || { echo UPLOAD_FAILED; rm -f /opt/aa/nbt-aad.new; exit 1; }; echo UPLOAD_OK; ls -l /opt/aa/nbt-aad | grep -q %CUR% || { echo CURRENT_DAEMON_NOT_AS_EXPECTED_STOP; exit 1; }; test ! -e /opt/aa/nbt-aad.release-backup || { echo BACKUP_NAME_IN_USE_STOP; exit 1; }; (slay nbt-aad; sleep 4; true); mv /opt/aa/nbt-aad /opt/aa/nbt-aad.release-backup && mv /opt/aa/nbt-aad.new /opt/aa/nbt-aad && chmod +x /opt/aa/nbt-aad && echo DAEMON_OK; cp /opt/aa/nbt-aad.env /opt/aa/nbt-aad.env.before-tile && { grep -q NBT_TILE /opt/aa/nbt-aad.env || echo NBT_TILE=1 >> /opt/aa/nbt-aad.env; } && echo ENV_OK; echo ==AFTER==; ls -l /opt/aa/nbt-aad /opt/aa/nbt-aad.release-backup /opt/aa/nbt-aad.env; cat /opt/aa/nbt-aad.env; echo ==END=='" < "%BIN%"
echo === done. Reboot is NOT needed: press Restart in the Android Auto menu. ===
