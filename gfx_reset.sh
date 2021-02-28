#!/bin/sh

systemctl stop amdgpu-clocks
echo "2" > /sys/class/drm/card0/device/hwmon/hwmon1/pwm1_enable
