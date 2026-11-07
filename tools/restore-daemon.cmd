@echo off
rem Rollback: put the release daemon back (the tile build becomes nbt-aad.tile.bad) and restore the env file.
rem Needs SSH open on the head unit + root password. If the head unit is in a boot loop because of the daemon,
rem switch "Start automatically" off in the Android Auto menu first (the plugin also skips autostart after 3 starts
rem within 15 minutes), then open SSH and run this.
set O=-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa -o MACs=+hmac-sha1,hmac-md5 -o KexAlgorithms=+diffie-hellman-group14-sha1,diffie-hellman-group1-sha1,diffie-hellman-group-exchange-sha1 -o Ciphers=+aes128-cbc,aes256-cbc,3des-cbc -o ConnectTimeout=5
echo === type the head unit password ===
ssh %O% root@169.254.199.99 "on -f /net/hu-omap/ /bin/sh -c 'mount -o remount rw /net/hu-omap/fs/sda0 || exit 1; test -f /opt/aa/nbt-aad.release-backup || { echo NO_RELEASE_BACKUP; exit 1; }; (slay nbt-aad; sleep 3; true); mv /opt/aa/nbt-aad /opt/aa/nbt-aad.tile.bad && mv /opt/aa/nbt-aad.release-backup /opt/aa/nbt-aad && echo DAEMON_RESTORED; test -f /opt/aa/nbt-aad.env.before-tile && cp /opt/aa/nbt-aad.env.before-tile /opt/aa/nbt-aad.env && echo ENV_RESTORED; echo ==AFTER==; ls -l /opt/aa/nbt-aad /opt/aa/nbt-aad.env; cat /opt/aa/nbt-aad.env; echo ==END=='"
echo === done ===
