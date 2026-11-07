@echo off
rem Test a daemon build ON THE HEAD UNIT from /tmp (nothing permanent), in the SAME environment the iDrive plugin
rem starts it with (LD_PRELOAD of the HMI). A bare SSH shell does NOT have that environment: a build can look fine
rem there and still crash when the plugin starts it (that is exactly how the static-libstdc++ build failed).
rem
rem Usage:  test-in-hmi-env.cmd path\to\nbt-aad-build [seconds]
rem Needs: SSH open on the head unit (e.g. Bavarian SSH), root password typed when asked.
rem It stops the running daemon first. Start it again afterwards from the Android Auto menu (Restart) or reboot.
set BIN=%~1
set SECS=%~2
if "%SECS%"=="" set SECS=60
if "%BIN%"=="" (echo usage: test-in-hmi-env.cmd build [seconds] & exit /b 1)
set O=-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa -o MACs=+hmac-sha1,hmac-md5 -o KexAlgorithms=+diffie-hellman-group14-sha1,diffie-hellman-group1-sha1,diffie-hellman-group-exchange-sha1 -o Ciphers=+aes128-cbc,aes256-cbc,3des-cbc -o ConnectTimeout=5 -o ServerAliveInterval=15
for %%F in ("%BIN%") do set SIZE=%%~zF
echo === build %BIN% (%SIZE% bytes), test %SECS% s - type the head unit password ===
ssh %O% root@169.254.199.99 "on -f /net/hu-omap/ /bin/sh -c 'cat > /tmp/nbt-aad.test; chmod +x /tmp/nbt-aad.test; ls -l /tmp/nbt-aad.test | grep -q %SIZE% || { echo UPLOAD_FAILED; exit 1; }; echo UPLOAD_OK; slay nbt-aad; sleep 5; LD_PRELOAD=libEGL_X.gpp.so:libGLESv2_X_FORWARD.gpp.so:libKD_X.gpp.so LD_LIBRARY_PATH=/lib:/usr/lib:/opt/sys/lib:/opt/mm/lib NBT_PTT_ASSISTANT=1 NBT_KEEP_PF=1 NBT_TILE=1 NBT_TILE_ALWAYS=1 NBT_LOG_FILE=/tmp/test.log /tmp/nbt-aad.test < /dev/null > /dev/null 2>&1 & P=$!; echo RUNNING; sleep %SECS%; kill $P; sleep 8; echo ==LOG==; grep -e Build -e LD_PRELOAD -e CRASH -e Tile -e registered -e link /tmp/test.log; echo ==END=='" < "%BIN%"
echo === done: look for [Tile] registered / main-menu tile shown, and no [CRASH] ===
