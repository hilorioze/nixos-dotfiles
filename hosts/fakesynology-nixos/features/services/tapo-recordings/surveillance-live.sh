#!/bin/bash
# the dsm runs it as root on boot: a triggered task scheduler script with this file's content
set -eu

# surveillance station touches `/tmp/ss_liveview_watch.<ds>.<camera id>.<stream>` every 30s while it shows a camera's live view
# fakesynology-nixos streams a camera only while its marker, named by its mac address, is fresh
mkdir --parents /volume1/surveillance-import/.live

declare -A macs

while true; do
  for watch in /tmp/ss_liveview_watch.*[0-9]; do
    if [[ ! -e $watch ]]; then
      continue
    fi

    IFS=. read -r _ _ id _ <<<${watch##*/}

    # the mac address the camera's address ends with, which only the camera's details have
    if [[ -z ${macs[$id]:-} ]]; then
      macs[$id]=$(/usr/syno/bin/synowebapi --exec api=SYNO.SurveillanceStation.Camera method=GetInfo version=8 cameraIds=\"$id\" 2>/dev/null | jq --raw-output .data.cameras[0].camPath | base64 --decode | xargs basename)
    fi

    marker=/volume1/surveillance-import/.live/${macs[$id]}
    if [[ -d /volume1/surveillance-import/${macs[$id]} && $watch -nt $marker ]]; then
      touch --reference=$watch $marker
    fi
  done

  sleep 1
done
