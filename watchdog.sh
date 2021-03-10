#!/bin/sh

MSG="GPU0 has crashed at $(date). Rebooting system in 30 minutes. Use shutdown -c to cancel."

wall "$MSG"
sudo /usr/bin/systemctl stop cryptomining.service
notify-send --urgency=critical --expire-time=1800000 --app-name=Watchdog "GPU Watchdog" "$MSG"
shutdown -r 30 "System Going Down for GPU Reset in 30 Minutes"
