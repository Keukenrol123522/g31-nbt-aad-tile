#!/bin/bash
# Build nbt-aad (QNX 6.5, ARMv7LE) with the community toolchain image (luka-dev/qnx65-armv7-toolchain, built with
# --build-arg BASE=base-4.9 --target base-env, tagged qnx65-49) inside Docker.
#
# IMPORTANT: this links libstdc++ DYNAMICALLY against the head unit's own libstdc++.so.6 (QNX 6.5 SDP, 6.0.13).
# Do NOT use -static-libstdc++ / -static-libgcc: the iDrive plugin starts the daemon with
# LD_PRELOAD=libEGL_X.gpp.so:libGLESv2_X_FORWARD.gpp.so:libKD_X.gpp.so, which already loads the head unit's GNU
# libstdc++ into the process. A second, static copy crashes (SIGSEGV right after the first DSI call) and, with
# "Start automatically" on, causes a boot loop. Check that the build only needs symbols the head unit's library has:
# tools/check-syms.sh <binary>.
#
# Usage: build-nbt-aad-dynamic.sh [source dir = milestone-7 of the patched tree]   -> <source dir>/nbt-aad
# (strip it afterwards: arm-unknown-nto-qnx6.5.0eabi-strip)
set -e
SRC=${1:-/root/aad/milestone-7}
mkdir -p /root/ovA/sys
docker run --rm qnx65-49 cat /opt/qnx650/target/qnx6/usr/include/sys/compiler_gnu.h > /root/ovA/sys/compiler_gnu.h
sed -i -E '/^typedef .*_(Int8t|Uint8t)[[:space:]]/ s/[[:space:]]*__attribute__\(\(__aligned__\(1\)\)\)//' /root/ovA/sys/compiler_gnu.h
cd "$SRC" && rm -f nbt-aad
docker run --rm -v "$PWD":/src -v /root/ovA:/ov:ro qnx65-49 make nbt-aad \
  QCC="qcc -I/ov -include stddef.h" \
  LDFLAGS="-L/opt/qnx650/target/qnx6/armle-v7/lib -L./lib -la2i_client -lsocket ./lib/libssl.so ./lib/libcrypto.so -lscreen -lusbdi -lm -Wl,-rpath,/opt/mm/lib:/lib:/usr/lib" > /root/aad-build.log 2>&1 || { tail -n 15 /root/aad-build.log; exit 1; }
ls -l nbt-aad
docker run --rm -v "$PWD":/r qnx65-49 arm-unknown-nto-qnx6.5.0eabi-readelf -d /r/nbt-aad | grep -E "NEEDED|RPATH" | sed 's/.*\(Shared library\|Library rpath\): //'
