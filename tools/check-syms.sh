#!/bin/bash
# Controleert of een QNX-binary alleen C++-runtime-symbolen nodig heeft die in libstdc++ 6.0.13 (QNX 6.5, = HU) bestaan.
B=$1
cp "$B" /root/out/check.bin
docker run --rm -v /root/out:/o qnx65-49 sh -c '
R=arm-unknown-nto-qnx6.5.0eabi-readelf
$R -W -D -s /o/check.bin | awk "\$8==\"UND\"{print \$9}" | sort -u > /o/und.txt
$R -W -D -s /opt/qnx650/target/qnx6/armle-v7/lib/libstdc++.so.6.0.13 | awk "\$8!=\"UND\"{print \$9}" | sort -u > /o/lib6013.txt
$R -W -d /o/check.bin | grep -e NEEDED -e RPATH'
cd /root/out
grep -e '^_Z' -e '^__cxa' -e '^__gxx' -e '^_Unwind' und.txt > undcpp.txt
echo "UND totaal: $(wc -l < und.txt), waarvan C++-runtime: $(wc -l < undcpp.txt)"
echo "ontbreekt in libstdc++ 6.0.13: $(comm -23 undcpp.txt lib6013.txt | wc -l)"
comm -23 undcpp.txt lib6013.txt
sha256sum "$B"; ls -l "$B"
