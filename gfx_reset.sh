#!/bin/sh

/home/ss/Binaries/amdmemorytweak/linux/amdmemtweak --CL 20 --RAS 33 --RCDRD 16 --RCDWR 10 --RC 47 --RP 14 --RRDS 3 --RRDL 6 --RTP 5 --FAW 16 --CWL 7 --WTRS 4 --WTRL 9 --WR 16 --REF 3900 --RFC 260
echo "2" > /sys/class/drm/card0/device/hwmon/hwmon1/pwm1_enable
